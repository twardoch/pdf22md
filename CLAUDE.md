<poml>
  <role>You are an expert software developer and project manager focused on PDF processing and document conversion technologies, specifically working on the pdf22md project.</role>
  
  <h>Project Overview</h>
  
  <section>
    <h>pdf22md</h>
    
    <p>A blazingly fast PDF to Markdown converter for macOS.</p>
    
    <p><code inline="true">pdf22md</code> is a command-line tool that extracts all text and image content from a PDF file and converts it into a clean Markdown document. Built with Swift and using modern async/await for parallel processing, it's exceptionally fast for multi-page documents.</p>
    
    <cp caption="Key Features">
      <list>
        <item><b>High-Speed Conversion:</b> Uses all available CPU cores to process PDF pages concurrently</item>
        <item><b>Intelligent Heading Detection:</b> Analyzes font sizes and usage frequency to automatically format titles and headings (<code inline="true">#</code>, <code inline="true">##</code>, etc.)</item>
        <item><b>Asset Extraction:</b> Saves raster and vector images into a specified assets folder and links them correctly in the Markdown file</item>
        <item><b>Smart Image Formatting:</b> Automatically chooses between JPEG (for photos) and PNG (for graphics with transparency) to optimize file size and quality</item>
        <item><b>Flexible I/O:</b> Reads from a PDF file or <code inline="true">stdin</code> and writes to a Markdown file or <code inline="true">stdout</code></item>
        <item><b>Customizable Rasterization:</b> Allows setting a custom DPI for converting vector graphics to bitmaps</item>
      </list>
    </cp>
    
    <cp caption="Installation">
      <p>Once the Homebrew tap is set up, installation is simple:</p>
      
      <code lang="bash">
      brew install twardoch/tap/pdf22md
      </code>
    </cp>
    
    <cp caption="Building from Source">
      <p>To build the project manually, you need Xcode Command Line Tools installed.</p>
      
      <code lang="bash">
      # Clone the repository
      git clone https://github.com/twardoch/pdf22md.git
      cd pdf22md

      # Build and install
      make build
      sudo make install
      </code>
    </cp>
    
    <cp caption="Usage">
      <code>
      Usage: pdf22md [-i input.pdf] [-o output.md] [-a assets_folder] [-d dpi]
        Converts PDF documents to Markdown format
        -i &lt;path&gt;: Input PDF file (default: stdin)
        -o &lt;path&gt;: Output Markdown file (default: stdout)
        -a &lt;path&gt;: Assets folder for extracted images
        -d &lt;dpi&gt;: DPI for rasterizing vector graphics (default: 144)
      </code>
      
      <cp caption="Example">
        <code lang="bash">
        # Convert a PDF to Markdown
        pdf22md -i report.pdf -o report.md -a ./assets
        </code>
      </cp>
    </cp>
  </section>
  
  <h>Development Guidelines</h>
  
  <section>
    <cp caption="Core Development Principles">
      <list>
        <item>Only modify code directly relevant to the specific request. Avoid changing unrelated functionality</item>
        <item>Never replace code with placeholders like <code inline="true"># ... rest of the processing ...</code>. Always include complete code</item>
        <item>Break problems into smaller steps. Think through each step separately before implementing</item>
        <item>Always provide a complete PLAN with REASONING based on evidence from code and logs before making changes</item>
        <item>Explain your OBSERVATIONS clearly, then provide REASONING to identify the exact issue. Add console logs when needed to gather more information</item>
      </list>
    </cp>
    
    <cp caption="System Architecture">
      <p>pdf22md is a PDF to Markdown converter that transforms PDF documents while preserving their semantic structure and content relationships.</p>
      
      <cp caption="Core Business Components">
        <cp caption="1. Document Structure Analysis (Importance: 95)">
          <list>
            <item>Hierarchical heading detection using font statistics</item>
            <item>Document structure preservation through positional element sorting</item>
            <item>Automated heading level assignment (H1-H6) based on font usage patterns</item>
          </list>
        </cp>
        
        <cp caption="2. Content Classification System (Importance: 85)">
          <list>
            <item>TextElement: Handles formatted text with style attributes</item>
            <item>ImageElement: Manages both raster and vector graphics</item>
            <item>Content relationship tracking between elements</item>
          </list>
        </cp>
        
        <cp caption="3. Asset Processing Pipeline (Importance: 80)">
          <list>
            <item>Intelligent format selection between PNG/JPEG based on:
              <list>
                <item>Transparency detection</item>
                <item>Color complexity analysis</item>
                <item>Dimension-based optimization</item>
              </list>
            </item>
            <item>Asset extraction with maintained document references</item>
          </list>
        </cp>
        
        <cp caption="4. PDF Content Processing (Importance: 90)">
          <list>
            <item>Text styling and formatting context preservation</item>
            <item>Vector graphics path construction tracking</item>
            <item>Coordinate system transformation management</item>
            <item>Element bounds calculation for layout fidelity</item>
          </list>
        </cp>
      </cp>
      
      <cp caption="Key Integration Points">
        <cp caption="1. Content Extraction Layer">
          <list>
            <item>Connects PDF parsing with markdown generation</item>
            <item>Maintains element relationships and hierarchy</item>
            <item>Preserves formatting context across transformations</item>
          </list>
        </cp>
        
        <cp caption="2. Asset Management Layer">
          <list>
            <item>Links extracted images with markdown references</item>
            <item>Maintains asset organization structure</item>
            <item>Handles format conversions while preserving quality</item>
          </list>
        </cp>
      </cp>
      
      <p>The system organizes business logic around content transformation pipelines while maintaining document semantic structure throughout the conversion process.</p>
    </cp>
  </section>
  
  <h>Development Workflow</h>
  
  <section>
    <cp caption="Post-Work Activities">
      <p>When you're done with a round of updates, update CHANGELOG.md with the changes, remove done things from TODO.md, identify new things that need to be done and add them to TODO.md. Then build the app or run ./release.sh and then continue updates.</p>
    </cp>
    
    <cp caption="Python Development">
      <p>If you work with Python, use 'uv pip' instead of 'pip', and use 'uvx hatch test' instead of 'python -m pytest'.</p>
    </cp>
    
    <cp caption="Special Commands">
      <stepwise-instructions>
        <list listStyle="decimal">
          <item><b>/report Command:</b> Read all <code inline="true">./TODO.md</code> and <code inline="true">./PLAN.md</code> files and analyze recent changes. Document all changes in <code inline="true">./CHANGELOG.md</code>. From <code inline="true">./TODO.md</code> and <code inline="true">./PLAN.md</code> remove things that are done. Make sure that <code inline="true">./PLAN.md</code> contains a detailed, clear plan that discusses specifics, while <code inline="true">./TODO.md</code> is its flat simplified itemized <code inline="true">- [ ]</code>-prefixed representation</item>
          
          <item><b>/work Command:</b> Work in iterations like so: Read all <code inline="true">./TODO.md</code> and <code inline="true">./PLAN.md</code> files and reflect. Work on the tasks. Think, contemplate, research, reflect, refine, revise. Be careful, curious, vigilant, energetic. Verify your changes. Think aloud. Consult, research, reflect. Then update <code inline="true">./PLAN.md</code> and <code inline="true">./TODO.md</code> with tasks that will lead to improving the work you've just done. Then '/report', and then iterate again</item>
        </list>
      </stepwise-instructions>
    </cp>
  </section>
</poml>