# APS Design Automation CLI Tool

A Python CLI tool for processing AutoCAD DWG files using Autodesk Platform Services (APS) Design Automation. This tool uploads DWG files, runs AutoLISP scripts to modify title blocks and save as PDF, then provides signed URLs for download.

## About This Sample Repository

This sample repository was generated using the new LLMS.txt files and Cursor.  They demonstrate "Vibe coding" a combo of APS Design Automation and Autocad AutoLisp into a python CLI tool:

- **AutoCAD LISP Documentation**: Generated using the new AutoCAD LISP LLMs documentation file (`aps.autodesk.com/llms-autolisp.txt`)
- **APS Design Automation**: Generated using the new APS full documentation file (`aps.autodesk.com/llms-full.txt`)

This repository serves as a test to see how smart Cursor is with detailed knowledge of AutoCAD Lisp and APS Design Automation for Autocad.

### File Structure

```
run-autolisp-via-aps
├── aps_design_automation.py    # Main CLI tool
├── requirements.txt            # Python dependencies
├── sample.env                  # Your environment variables (rename to .env)
├── README.md                   # This file
└── scripts/                    # Script files directory
    ├── modify_title.lsp        # AutoLISP script for title block modification
    ├── extract_data.lsp        # AutoLISP script for data extraction
    ├── execute_script.scr      # Single .scr file for all LISP scripts
    └── work_item.json          # Flexible work item template
```

## Vibe Coded - Prompt

This tool was created based on the following prompt with both `llms-full.txt` and `llms-autolisp.txt` :

> "Help me write a python cli tool, that sends script to APS Design Automation for Autocad without any C# or compile step like a DLL since I'm running on a mac.
> 
> The script is a combo of AutoLisp and .scr
> 
> The python tool should take a local DWG file as input, upload it to a APS bucket (and it will need .env with APS_CLIENTID KEY and BUCKET_NAME) run a LISP script, then provide a signedURL to download the file.
> 
> The script should:
> 1. modify the title block to "hello world"
> 2. save a PDF file
> 
> The end result is a signedURL to a PDF version of a DWG containing a new title block."

## Features

- 🚀 Upload DWG files to APS bucket
- 🔧 Execute AutoLISP and .scr scripts on AutoCAD files
- 📄 Modify title blocks and save as PDF
- 🔗 Generate signed URLs for file download
- ⏱️ Configurable timeouts and URL expiration
- 🖥️ Cross-platform (works on macOS, Linux, Windows)
- 📁 Modular script files for easy customization
- 🎯 Single flexible CLI tool for multiple workflows

## Prerequisites

1. **APS Account**: You need an Autodesk Platform Services (APS) account
2. **APS Application**: Create an application in the APS Developer Portal
3. **APS Bucket**: This tool will create a temporary OSS bucket for file storage
4. **Python 3.7+**: Ensure Python is installed on your system

## Setup

### 1. Install Dependencies

```bash
pip install -r requirements.txt
```

### 2. Get APS Credentials

1. Go to [APS Developer Portal](https://developer.autodesk.com/)
2. Create a new application
3. Note your Client ID and Client Secret
4. Create a bucket for file storage
5. Update your `sample.env` file with these values

### 3. Configure Environment Variables

Update the sample.env file with your APS credentials and rename it:

```env
APS_CLIENT_ID=your_aps_client_id_here
APS_CLIENT_SECRET=your_aps_client_secret_here
APS_BUCKET_NAME=your_bucket_name_here
```

```bash
mv sample.env .env
```

### Sample DWG Files for Testing

Before using the LISP scripts, you'll need sample DWG files to test with. You can find sample files at:

- **Sample Civil DWG**: [Autodesk Support Article](https://www.autodesk.com/support/technical/article/caas/tsarticles/ts/6XGQklp3ZcBFqljLPjrnQ9.html)
- **Sample DWG with Title Block**: [Autodesk Support Article](https://www.autodesk.com/support/technical/article/caas/tsarticles/ts/6XGQklp3ZcBFqljLPjrnQ9.html)

These sample files are perfect for testing both the title block modification and data extraction scripts.

## Usage

### Basic Usage (default lisp script = "Title Block Modification")

```bash
python aps_design_automation.py path/to/your/file.dwg
```

### Data Extraction

```bash
python aps_design_automation.py path/to/your/civil-file.dwg \
  --lisp extract_data.lsp \
  --output extracted_data.csv \
  --activity AutoCAD.ExtractData+prod
```

### Advanced Usage

```bash
# With custom timeout and URL expiration
python aps_design_automation.py path/to/your/file.dwg --timeout 600 --expires 7200

# Custom LISP script
python aps_design_automation.py path/to/your/file.dwg \
  --lisp my_custom.lsp \
  --output my_result.txt \
  --activity AutoCAD.MyCustom+prod

# Get help
python aps_design_automation.py --help
```

### Example Output

```
Processing: /path/to/file.dwg
Using LISP: modify_title.lsp
Output: result.pdf
Download URL: https://developer.api.autodesk.com/...
```

## How It Works

1. **File Upload**: The DWG file is uploaded to your APS bucket
2. **Script Execution**: AutoLISP and .scr scripts are uploaded and executed
3. **Title Block Modification**: The AutoLISP script finds and modifies title block text to "HELLO WORLD"
4. **PDF Generation**: The drawing is saved as a PDF file
5. **Download URL**: A signed URL is generated for downloading the PDF

## LISP Scripts

The tool includes two pre-built AutoLISP scripts for common workflows:


### 1. `scripts/modify_title.lsp` - Title Block Modification

**Purpose**: Modifies title block text in AutoCAD drawings and saves as PDF.

**What it does**:
- Searches for text objects containing "TITLE" (case-insensitive) in both modelspace and paperspace
- Replaces the found text with "HELLO WORLD"
- Saves the drawing as a PDF using the "DWG To PDF.pc3" plotter
- Provides feedback about modifications made

**Input**: 
- AutoCAD DWG file (uploaded to APS)

**Output**: 
- PDF file with modified title block
- File saved as `result.pdf` (or custom name via `--output`)

**Usage**:
```bash
# Default usage (uses this script automatically)
python aps_design_automation.py path/to/file.dwg

# Explicit usage
python aps_design_automation.py path/to/file.dwg \
  --lisp modify_title.lsp \
  --output modified_drawing.pdf
```

**Customization**:
- Edit the script to change search patterns (e.g., look for different text)
- Modify the replacement text (currently "HELLO WORLD")
- Adjust PDF settings (paper size, orientation, plotter configuration)
- Add additional AutoCAD operations

### 2. `scripts/extract_data.lsp` - Data Extraction

**Purpose**: Extracts GIS data, text labels, and dimensions from AutoCAD drawings to CSV format.

**What it does**:
- Extracts all text objects (regular text and MText)
- Extracts dimension objects with their values
- Extracts point objects (potential GIS coordinates)
- Extracts line start/end points
- Extracts polyline vertices (potential GIS polygons)
- Saves all data to a CSV file with coordinates and metadata

**Input**: 
- AutoCAD DWG file (uploaded to APS)

**Output**: 
- CSV file with extracted data
- File saved as `extracted_data.csv` (or custom name via `--output`)

**CSV Format**:
```csv
Type,Layer,X,Y,Z,Text,Additional_Data
TEXT,0,100.000000,200.000000,0.000000,"Sample Text",
DIMENSION,DIM,150.000000,250.000000,0.000000,"50.0",
POINT,POINTS,300.000000,400.000000,0.000000,,
LINE,LINES,100.000000,200.000000,0.000000,START,
LINE,LINES,200.000000,300.000000,0.000000,END,
POLYLINE,POLYGONS,100.000000,200.000000,0.000000,VERTEX,
```

**Usage**:
```bash
python aps_design_automation.py path/to/file.dwg \
  --lisp extract_data.lsp \
  --output extracted_data.csv \
  --activity AutoCAD.ExtractData+prod
```

**Data Types Extracted**:
- **TEXT**: Regular text objects with coordinates and content
- **MTEXT**: Multi-line text objects
- **DIMENSION**: Dimension objects with their values
- **POINT**: Point objects (potential GIS coordinates)
- **LINE**: Line start/end points
- **POLYLINE**: All vertices of polylines (potential GIS polygons)

**Customization**:
- Add extraction of additional AutoCAD object types
- Modify the CSV format and columns
- Filter data by layer or other criteria
- Add coordinate system transformations

## Script Files

The tool uses separate script files for better maintainability and customization:

### AutoLISP Scripts

- **`scripts/modify_title.lsp`**: Modifies title blocks and saves as PDF
- **`scripts/extract_data.lsp`**: Extracts GIS data, text labels, and dimensions to CSV

### Execution Script

- **`scripts/execute_script.scr`**: Single .scr file that executes any LISP script (uses template replacement)

### Customizing Scripts

You can easily modify the scripts to suit your needs:

1. **Edit existing LISP scripts**:
   - Modify search patterns, replacement text, or output formats
   - Add additional AutoCAD operations
   - Change file output settings

2. **Create new LISP scripts**:
   - Add any `.lsp` file to the `scripts/` directory
   - Use the `--lisp` option to specify which script to run
   - Follow the same pattern as existing scripts

3. **Script Requirements**:
   - Must be valid AutoLISP code
   - Should handle both modelspace and paperspace if needed
   - Should provide feedback about operations performed
   - Should save output files to the working directory

## Configuration Options

### Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `APS_CLIENT_ID` | Your APS application client ID | Yes |
| `APS_CLIENT_SECRET` | Your APS application client secret | Yes |
| `APS_BUCKET_NAME` | Name of your APS bucket | Yes |
| `APS_REGION` | APS region (default: us-east-1) | No |

### Command Line Options

| Option | Description | Default |
|--------|-------------|---------|
| `--lisp` | LISP script file to use | `modify_title.lsp` |
| `--output` | Output file name | `result.pdf` |
| `--activity` | Design Automation activity ID | `AutoCAD.ModifyTitleBlock+prod` |
| `--timeout` | Timeout in seconds for work item completion | 300 |
| `--expires` | Download URL expiration time in seconds | 3600 |

## Troubleshooting

### Common Issues

1. **Missing Environment Variables**
   ```
   Error: Missing required environment variables. Please check your .env file.
   ```
   **Solution**: Ensure all required environment variables are set in your `.env` file.

2. **Script Files Not Found**
   ```
   Error: Script file not found. Please ensure the scripts directory exists with the required files.
   ```
   **Solution**: Make sure the `scripts/` directory exists with the required files.

3. **Authentication Errors**
   ```
   Error: 401 Unauthorized
   ```
   **Solution**: Verify your APS Client ID and Client Secret are correct.

4. **Bucket Not Found**
   ```
   Error: 404 Not Found
   ```
   **Solution**: Ensure the bucket name in your `.env` file exists in your APS account.

5. **Work Item Timeout**
   ```
   Error: Work item did not complete within 300 seconds
   ```
   **Solution**: Increase the timeout value using the `--timeout` option.

### Debug Mode

For detailed debugging, you can modify the script to include more verbose logging:

```python
import logging
logging.basicConfig(level=logging.DEBUG)
```


## Security Notes

- Never commit your `.env` file to version control
- Keep your APS credentials secure
- Use environment variables for sensitive information
- Regularly rotate your APS client secrets

## Support

For issues related to:
- **APS API**: Check the [APS Documentation](https://developer.autodesk.com/en/docs/)
- **Design Automation**: Refer to [Design Automation Documentation](https://help.autodesk.com/view/OARX/2024/ENU/?guid=GUID-7B4A4CC0-5E3A-4C8A-8B4A-4CC0-5E3A-4C8A)
- **AutoLISP**: See [AutoLISP Reference](https://help.autodesk.com/view/OARX/2024/ENU/?guid=GUID-0365EB64-531D-4CC0-B740-E756CC5E5AB6)

## License

This project is provided as-is for educational and development purposes. 
