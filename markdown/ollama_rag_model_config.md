
Here is a comprehensive guide to architecting your local JavaScript RAG (Retrieval-Augmented Generation) application.

### Architecture Overview
*   **Language:** Node.js (JavaScript/TypeScript)
*   **Orchestration:** Ollama (Local Inference)
*   **Vector Database:** PostgreSQL with `pgvector` extension
*   **Workflow:**
    1.  **Parse:** Extract raw text from PDF.
    2.  **Clean:** Normalize text and split into chunks.
    3.  **Embed:** Convert chunks to vectors using a local embedding model.
    4.  **Store:** Save vectors and text metadata to Postgres.
    5.  **Search:** Convert user query to vector, perform cosine similarity search.
    6.  **Generate:** Inject retrieved chunks into a prompt for the LLM to generate an answer.

---

### 1. Best Local Models for Ollama

For a RAG system, you need two distinct models: a **Retriever** (Embedding Model) and a **Reader** (Generative LLM).

#### A. Best Embedding Model (The Retriever)
To get the "cleanest most readable textual chunks," you need a model that understands semantic context well, ensuring you retrieve paragraphs that actually answer the question rather than just matching keywords.

**Recommendation: `mxbai-embed-large`**

*   **Why:** It is currently one of the highest performing open-source embedding models that runs efficiently locally. It has a dimension of 1024, which offers a great balance between semantic granularity and speed.
*   **Alternative:** `nomic-embed-text` (v1.5). This is excellent for dense, technical content and is very fast (lighter on VRAM).

#### B. Best Generative Models (The Reader)
You want a model that follows instructions well, summarizes retrieved context accurately, and doesn't hallucinate.

**Top Pick: `llama3` (8B Instruct)**
*   **Why:** Meta's Llama 3 is the current gold standard for 7B-8B parameter models. It handles complex reasoning, follows strict system prompts, and has a very low hallucination rate compared to older models.
*   **Best For:** General purpose, precise technical documentation, and following citation rules.

**Runner Up: `mistral` (7B Instruct)**
*   **Why:** Mistral is extremely fast and "punchy." If you find Llama 3 is running too slowly on your hardware, Mistral is a great fallback with high quality output.

---

### 2. Ollama Modfile Configuration

To optimize these models for RAG, you should create custom models using Modfiles. This allows you to lock in low temperatures (to reduce hallucinations), extend the context window (to fit more PDF chunks), and enforce strict System Prompts.

You create these by running `ollama create <name> -f <filename>`.

#### A. Optimized Embedding Model (`rag-embedder`)
Use this to create a model optimized for high-fidelity retrieval.

```modfile
# Modfile: rag-embedder.modelfile
FROM mxbai-embed-large

# Parameters
# Mxbai runs best with defaults, but we can ensure a specific batch size for bulk processing
PARAMETER num_ctx 8192
```

#### B. Optimized LLM for RAG (`rag-llama3`)
This configuration enforces strict adherence to the provided context (the PDF chunks). We set the temperature very low so the model relies on facts rather than creativity.

```modfile
# Modfile: rag-llama3.modelfile
FROM llama3

# Set parameters for RAG
PARAMETER temperature 0.1      # Low temp for factual, deterministic answers
PARAMETER num_ctx 32768        # Maximize context window to fit many chunks
PARAMETER repeat_penalty 1.15  # Prevent the model from repeating itself
PARAMETER top_p 0.9

# System Prompt
# This is critical for RAG. It forces the model to stick to the provided context.
SYSTEM """
You are a precise and helpful assistant designed to answer questions based strictly on the provided context from PDF documents.

Guidelines:
1. Answer the user's question using ONLY the context provided below.
2. If the answer is not in the context, state clearly: "The provided documents do not contain information about this."
3. Do not use outside knowledge or hallucinate facts.
4. Cite the source document or page when possible.
5. Maintain the original tone and technical accuracy of the source text.
"""
```

#### C. Optimized LLM for Conversational Search (`rag-mistral`)
If you want slightly faster, more conversational responses.

```modfile
# Modfile: rag-mistral.modelfile
FROM mistral

PARAMETER temperature 0.2
PARAMETER num_ctx 16384

SYSTEM """
You are an intelligent document assistant. Your goal is to synthesize answers from the given text excerpts.
Be concise. If the context does not support the answer, admit it.
"""
```

---

### 3. JavaScript Implementation Strategy

Here is how you should structure the application logic in Node.js to ensure "clean" textual chunks.

#### Dependencies
```bash
npm install ollama pg pdf-parse
```

#### Step 1: Parsing and Cleaning (The "Clean Chunk" Strategy)
Embedding models prefer dense, semantic blocks. Bad parsing ruins RAG.

```javascript
const pdf = require('pdf-parse');
const { Ollama } = require('ollama');

// Helper: Simple text cleaning to remove PDF artifacts (excessive newlines, headers)
function cleanText(text) {
  return text
    .replace(/\s+/g, ' ')  // Collapse multiple spaces/newlines into single space
    .replace(/(\w)-\n(\w)/g, '$1$2') // Fix hyphenated words broken by lines
    .trim();
}

// Helper: Semantic Chunking
function chunkText(text, maxChunkSize = 1000) {
  const chunks = [];
  const sentences = text.match(/[^.!?]+[.!?]+/g) || []; // Split by sentence
  let currentChunk = '';

  for (const sentence of sentences) {
    if ((currentChunk + sentence).length < maxChunkSize) {
      currentChunk += ' ' + sentence;
    } else {
      chunks.push(cleanText(currentChunk));
      currentChunk = sentence;
    }
  }
  if (currentChunk) chunks.push(cleanText(currentChunk));
  return chunks;
}
```

#### Step 2: Generating Embeddings & Storing in Postgres
Assuming you have a table `documents` with a `vector` column (created using `pgvector`).

```javascript
const ollama = new Ollama({ host: 'http://localhost:11434' });

async function processPDF(pdfBuffer, client) {
  const data = await pdf(pdfBuffer);
  const chunks = chunkText(data.text);

  for (const chunk of chunks) {
    // 1. Generate Embedding using the custom model
    const embeddingResponse = await ollama.embeddings({
      model: 'rag-embedder',
      prompt: chunk,
    });

    // 2. Store in Postgres (Using pg node client)
    // Assumes table schema: id, content, embedding (vector(1024))
    const query = `
      INSERT INTO document_chunks (content, embedding)
      VALUES ($1, $2)
    `;
    
    // Convert array of floats to postgres vector format string: "[0.1, 0.2, ...]"
    const vectorString = `[${embeddingResponse.embedding.join(',')}]`;
    
    await client.query(query, [chunk, vectorString]);
  }
}
```

#### Step 3: Searching and Generating
This is the "RAG" loop. We query the vector DB, then pass the results to the LLM.

```javascript
async function searchAndQuery(userQuery, client) {
  // 1. Embed the user query
  const queryEmbedding = await ollama.embeddings({
    model: 'rag-embedder',
    prompt: userQuery,
  });
  
  const vectorString = `[${queryEmbedding.embedding.join(',')}]`;

  // 2. Perform Vector Search in Postgres
  // We find the top 3 chunks most similar to the query
  const searchQuery = `
    SELECT content, 
           1 - (embedding <=> $1) as similarity
    FROM document_chunks
    ORDER BY embedding <=> $1
    LIMIT 3
  `;
  
  const { rows } = await client.query(searchQuery, [vectorString]);
  
  // 3. Construct the Context
  const contextText = rows
    .map((row, i) => `Document Excerpt ${i+1}:\n${row.content}`)
    .join('\n\n---\n\n');

  // 4. Generate Response using Custom LLM
  const response = await ollama.chat({
    model: 'rag-llama3',
    messages: [
      { 
        role: 'system', 
        content: "You are a helpful assistant. Use the following context to answer the user's question." 
      },
      {
        role: 'user',
        content: `Context:\n${contextText}\n\nUser Question:\n${userQuery}`
      }
    ],
    stream: false // Set to true for streaming responses
  });

  return response.message.content;
}
```

### Summary of Best Practices for this Stack

1.  **Context Window:** Always ensure your `num_ctx` in the Modfile is larger than your accumulated chunk size. Llama 3 supports up to 8k natively, but scaling it to 16k or 32k in the Modfile helps you fit more citations.
2.  **Temperature:** Keep it **0.1** for PDF parsing. You want the LLM to extract facts, not write fiction.
3.  **Hybrid Search:** If your PDFs contain specific part numbers or code keywords that get lost in semantic embeddings, consider implementing "Hybrid Search" (standard PostgreSQL `LIKE %keyword%` combined with vector similarity).
4.  **Chunking:** The "Cleanest" chunks come from splitting by **Sentence** or **Paragraph**, not by fixed character count. Fixed splitting often cuts sentences in half, confusing the embedding model. Use the recursive logic provided above.