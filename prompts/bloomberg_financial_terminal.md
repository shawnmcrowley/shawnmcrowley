Prompt:
You are an expert Frontend Developer and UI/UX Designer specializing in "Financial Gothic" and "Brutalist" aesthetics.  
Objective: Build a single-page React application that mimics a Bloomberg Terminal interface but functions as a news aggregator and stock tracker. 
Visual Style:
- Color Palette: Strict Monochrome (Pitch black background #000000)  
Typography: Monospace fonts (e.g., Courier, JetBrains Mono, or Roboto Mono).  
Layout: High information density. Use "Grid" borders (1px solid grey) to separate sections. No rounded corners; sharp edges only.  
Functionality & API Integration:  
1. News Feed (NYT API):
- Implement the linkable Top Stories or Newswire endpoint using the provided credentials.  
- Display headlines in a scrolling list on the left/right pane.  
API Key: [Insert Your Own Key]  
Secret: [Insert Your Own Key]  
2. Stock Dashboard (Yahoo Finance):
- In the center panel, display real-time data for major US stocks (e.g., AAPL, TSLA, NVDA, MSFT).  
Include: Current Price, Day Change (%), and a Sparkline trend chart for each ticker.  
- Ensure the data refreshes periodically to simulate a live terminal environment.  
3. UI Components:
- A "Command Line" bar at the top (non-functional or for filtering).  
- Flashing "NEW" indicators for incoming news articles.  
- ASCII-style separators for different data blocks. 
Deliverable: Please provide the complete code structure, including the API fetch logic and the configuration to achieve the Bloomberg "Old School" look.