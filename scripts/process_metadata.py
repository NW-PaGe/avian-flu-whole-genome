import sys
import subprocess

# Ensure openpyxl is installed
try:
    import openpyxl
except ImportError:
    print("Missing dependency: 'openpyxl'. Installing now...")
    subprocess.check_call([sys.executable, "-m", "pip", "install", "openpyxl"])
    import openpyxl  # Try importing again after installation

import argparse
import pandas as pd
import os

def main():
    # Parse command-line arguments
    parser = argparse.ArgumentParser(description="Process metadata.")
    parser.add_argument('--input', required=True, help="Path to the input metadata file.")
    parser.add_argument('--output', required=True, help="Path to the output processed metadata file.")
    args = parser.parse_args()

    # Ensure the input file exists
    if not os.path.exists(args.input):
        raise FileNotFoundError(f"Input file not found: {args.input}")

    # Read the metadata file
    metadata = pd.read_excel(args.input, engine="openpyxl")  # Explicitly specify openpyxl engine

    # Filter out rows with "egg" or "cell" in passage_category
    metadata = metadata[~metadata['passage_category'].str.contains('egg|cell', case=False, na=False)]

    # Parse the 'Location' variable into separate columns
    location_split = metadata['Location'].str.split('/', expand=True)
    metadata['region'] = location_split[0].str.strip()  # Remove leading/trailing whitespaces
    metadata['country'] = location_split[1].str.strip()
    metadata['division'] = location_split[2].str.strip()
    metadata['location'] = location_split[3].str.strip()

    # Add a new column 'virus'
    metadata['virus'] = 'avian_flu'

    # Rename columns
    metadata.rename(columns={'Isolate_Name': 'strain', 'Collection_Date': 'date', 'Host': 'host'}, inplace=True)

    # Ensure Collection_Date is treated as a string and format it as needed
    metadata['date'] = metadata['date'].astype(str)  # Ensure it's a string
    metadata['date'] = metadata['date'].apply(lambda x: x if 'XX' in x else pd.to_datetime(x, errors='coerce').strftime('%Y-%m-%d') if pd.to_datetime(x, errors='coerce') is not pd.NaT else 'NaT')

    # Subset to the required columns
    metadata_subset = metadata[['strain', 'virus', 'host', 'date', 'region', 'country', 'division', 'location']]

    # Write the output to a .tsv file
    metadata_subset.to_csv(args.output, sep='\t', index=False)
    print(f"Output written to: {args.output}")

if __name__ == "__main__":
    main()
