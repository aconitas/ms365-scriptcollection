import base64
import csv
import xml.etree.ElementTree as ET

# Load the XML file
tree = ET.parse('.\\input\\Safeid-ST.xml')
root = tree.getroot()

# Counters
xml_counter = 0
csv_counter = 0
output_counter = 0

# Read the PowerShell output CSV file and create a mapping for 'Token Serial' to 'UPN'
token_login_map = {}
with open('.\\input\\All_Active_SafeID_Tokens_with_UPN.csv', 'r') as csvfile:
    reader = csv.DictReader(csvfile)
    for row in reader:
        csv_counter += 1
        token_login_map[row['Token Serial']] = {'UPN': row['UPN']}

# Open a CSV file for writing
with open('.\\output\\azure-oath-import.csv', 'w', newline='') as csvfile:
    fieldnames = ['upn', 'serial number', 'secret key', 'time interval', 'manufacturer', 'model']
    writer = csv.DictWriter(csvfile, fieldnames=fieldnames)

    # Write the header row
    writer.writeheader()

    # Iterate through all tokens in the XML tree
    for token in root.findall('.//token'):
        xml_counter += 1
        serial = token.find('serial').text
        seed_base64 = token.find('seed').text

        # Convert Base64 to Base32
        seed_bytes = base64.b64decode(seed_base64)
        seed_base32 = base64.b32encode(seed_bytes).decode('utf-8')

        token_info = token_login_map.get(serial, {"UPN": "N/A"})
        upn = token_info['UPN']

        # Skip rows where 'UPN' is 'null', 'N/A' or empty
        if upn in ['null', '', 'N/A']:
            continue

        # Write to the CSV file
        writer.writerow({
            'upn': upn,
            'serial number': serial,
            'secret key': seed_base32,
            'time interval': '60',
            'manufacturer': 'Deepnet Security',
            'model': 'SafeID/Classic'
        })

        output_counter += 1

# Print statistics
print(f"SafeID/Time-Based Tokens available  : {xml_counter}")
print(f"SafeID/Time-Based Tokens active     : {csv_counter}")
print(f"The azure-oath-import.csv file contains {output_counter} tokens")
