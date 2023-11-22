# How To
1. DualShield Administration Console > Tasks > Export SafeID/TimeBased Tokens
2. C:\Program Files\Deepnet DualShield\export\Safeid-ST.xml kopieren
3. DualShield Administration Console > Reports > Tab: Reports > All_Active_SafeID_Tokens > Run
4. DualShield Administration Console > Reports > Tab: Results > All_Active_SafeID_Tokens > Export as CSV
    - Report Output Configuration
        - Format: CSV
        - Output Columns: Token Serial, Product, Login Name
        - Page Setup: 
            - Only Show Column Headers in First Page: True
            - Show Page Number: false
            - Show Creation Date: false
    - Zeile 1 und 2 der CSV entfernen!
5. Run Get-UserUPN.ps1 from a Domain Controller with the 'All_Active_SafeID_Tokens.csv' in the same directory
6. Put 'All_Active_SafeID_Tokens_with_UPN.csv' into the input directory and run the 'create_azure_import_file.py'

# Dependencies
- Python Interpreter >= v3.11 (https://www.python.org/downloads/)