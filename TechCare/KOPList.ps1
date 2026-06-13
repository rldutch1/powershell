# ----------------------------------------------------------------------------
# Script Author: Robert Holland 
# Script Name: KOPList.ps1
# Creation Date: Fri Jun 12 2026 21:24:21 GMT-0700 (US Mountain Standard Time)
# Last Modified: 
# Copyright (c)2026
# Purpose: Sort through a detailed medication administration CSV file and create a KOP list HTML table based on username.
# ----------------------------------------------------------------------------
 

$csvPath  = "detailed-medication-administrations-DATE-HERE.csv"
$outPath  = "KOPList.html"
$tcusername = "Robert Holland Registered Nurse"

# Import CSV, filter by username, and make ADC Number unique
$data = Import-Csv -Path $csvPath |
    Where-Object { $_.UserName -eq $tcusername } |
    Group-Object 'Patient Id' |                     # <-- Group by ADC Number
    ForEach-Object { $_.Group | Select-Object -First 1 } |   # <-- Keep only one row per ADC
    Select-Object 'Patient Id','Patient Name','Current Housing Location'

# Build HTML rows
$rows = foreach ($row in $data) {
    $adc = $row.'Patient ID'
    $link = "https://adcrr.techcareehr.com/dashboard/patient?id=$adc"

    "<tr>" +
    "<td style='padding:0; margin:0;'>
         <a href='$link' target='_blank' 
            style='display:block;
                   width:100%;
                   height:100%;
                   background:#0078D4;
                   color:white;
                   text-align:center;
                   padding:10px 0;
                   text-decoration:none;
                   font-weight:bold;
                   border-radius:4px;'>
            View in TechCare $adc
         </a>
     </td>" +
    "<td>$($row.'Patient Name')</td>" +
    "<td>$($row.'Current Housing Location')</td>" +
    "</tr>"
} -join "`n"

# Full HTML with sortable columns
$html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Filtered Patient Housing Dashboard</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ccc; padding: 8px; text-align: left; }
        th { cursor: pointer; background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #fafafa; }
    </style>
    <script>
        function sortTable(n) {
            var table = document.getElementById("patientTable");
            var switching = true;
            var dir = "asc";
            var switchcount = 0;

            while (switching) {
                switching = false;
                var rows = table.rows;

                for (var i = 1; i < (rows.length - 1); i++) {
                    var shouldSwitch = false;
                    var x = rows[i].getElementsByTagName("TD")[n];
                    var y = rows[i + 1].getElementsByTagName("TD")[n];

                    var xContent = x.textContent || x.innerText;
                    var yContent = y.textContent || y.innerText;

                    if (dir === "asc") {
                        if (xContent.toLowerCase() > yContent.toLowerCase()) {
                            shouldSwitch = true;
                            break;
                        }
                    } else if (dir === "desc") {
                        if (xContent.toLowerCase() < yContent.toLowerCase()) {
                            shouldSwitch = true;
                            break;
                        }
                    }
                }

                if (shouldSwitch) {
                    rows[i].parentNode.insertBefore(rows[i + 1], rows[i]);
                    switching = true;
                    switchcount++;
                } else {
                    if (switchcount === 0 && dir === "asc") {
                        dir = "desc";
                        switching = true;
                    }
                }
            }
        }
    </script>
</head>
<body>
    <h2>Patient Housing Dashboard — $tcusername</h2>
    <table id="patientTable">
        <thead>
            <tr>
                <th onclick="sortTable(0)">ADC Number</th>
                <th onclick="sortTable(1)">Patient Name</th>
                <th onclick="sortTable(2)">Current Housing Location</th>
            </tr>
        </thead>
        <tbody>
$rows
        </tbody>
    </table>
</body>
</html>
"@

# Write HTML file
$html | Set-Content -Path $outPath -Encoding UTF8

Write-Host "Filtered HTML dashboard generated at $outPath"
Start-Process "KOPList.html"