
# ----------------------------------------------------------------------------
# Script Author: Robert Holland RN
# Script Name: pdma.ps1
# Creation Date: Thu Jun 04 2026 15:32:39 GMT-0700 (US Mountain Standard Time)
# Last Modified: 
# Copyright (c)2026
# Purpose: Parse the detailed medication administration .csv file and generate a Gabapentin and Suboxone report based on username.
# Purpose: Parse detailed medication administration CSV and generate
#          HTML report with sortable tables.
# ----------------------------------------------------------------------------

# -----------------------------------------
#   CONFIGURATION
# -----------------------------------------

# Enter date ONE time here
$thedate = Get-Date "09-13-2026"

# TechCare Username
$tcusername = "Robert Holland Registered Nurse"

#Suboxone beginning count:
    $SUB_2mg = 192
    $SUB_8mg = 1533

#Gabapentin beginning count:
    $G_100mg = 936
    $G_300mg = 512 
    $G_400mg = 156
    $G_600mg = 384
    $G_800mg = 393

#Gabapentin wasted:
    $G_WASTE100mg = 0
    $G_WASTE300mg = 0
    $G_WASTE400mg = 0
    $G_WASTE600mg = 0
    $G_WASTE800mg = 0

#Suboxone wasted:
    $SUB_WASTE_2mg = 0
    $SUB_WASTE_8mg = 0

# ----------------------------------------------------------------------------
# Detailed Medication Administration filename
#$dma = "C:/Users/robert.holland/Downloads/detailed-medication-administrations-07-13-2026.csv"
$dma = "C:/Users/robert.holland/Downloads/detailed-medication-administrations-$($thedate.ToString('MM-dd-yyyy')).csv"
$TextFile = "C:\Users\robert.holland\Downloads\PendingPharmacyDelivery-$($thedate.ToString('MM-dd-yyyy')).txt"

# Medication Administration Date
#$mad = "7/13/2026"
$mad = $thedate.ToString("M/d/yyyy")

# -----------------------------------------
#   BEGINNING INVENTORY COUNTS
# -----------------------------------------

# Gabapentin beginning counts
$BeginCounts = @{
    100 = $G_100mg #
    300 = $G_300mg #
    400 = $G_400mg #
    600 = $G_600mg #
    800 = $G_800mg #
}

# Buprenorphine/Naloxone beginning counts
$BupeBeginCounts = @{ 
    "2-0.5" = $SUB_2mg#
    "8-2"   = $SUB_8mg# 
}

$GabapentinWaste = @{
    100 = $G_WASTE100mg
    300 = $G_WASTE300mg
    400 = $G_WASTE400mg
    600 = $G_WASTE600mg
    800 = $G_WASTE800mg
}

$BupeWaste = @{
    "2-0.5" = $SUB_WASTE_2mg
    "8-2" = $SUB_WASTE_8mg
}

# Create timestamped log filename
$timestamp = (Get-Date).ToString("yyyy-MM-dd_HHmmss")
$reportFile = "final_medication_report_$timestamp.html"

# Import CSV
$data = Import-Csv $dma

# -----------------------------------------
#   FILTER: GABAPENTIN
# -----------------------------------------

$gabapentin = $data | Where-Object {
    $_."UserName" -like $tcusername -and
    #$_."drug name" -eq "Morphine Sulfate ER Oral" -and
    $_."drug name" -eq "Gabapentin Oral" -and
    ([int]$_."Drug Strength") -in 100,300,400,600,800 -and
    ([datetime]$_."Administration Date").Date -eq (Get-Date $mad).Date
}

# -----------------------------------------
#   FILTER: BUPRENORPHINE/NALOXONE (8-2)
# -----------------------------------------
$bupe = $data | Where-Object {
    $_."UserName" -like $tcusername -and
    $_."drug name" -eq "Buprenorphine HCl-Naloxone HCl Sublingual" -and
    $_."Drug Strength" -like "8-2" -and
    $_."Administration Type" -ne "Refused" -and
    $_."Administration Type" -ne "Administration Cancelled" -and
    ([datetime]$_."Administration Date").Date -eq (Get-Date $mad).Date
}

# -----------------------------------------
#   FILTER: BUPRENORPHINE/NALOXONE (2-0.5)
# -----------------------------------------
$bupeLow = $data | Where-Object {
    $_."UserName" -like $tcusername -and
    $_."drug name" -eq "Buprenorphine HCl-Naloxone HCl Sublingual" -and
    $_."Drug Strength" -eq "2-0.5" -and
    $_."Administration Type" -ne "Refused" -and
    $_."Administration Type" -ne "Administration Cancelled" -and
    ([datetime]$_."Administration Date").Date -eq (Get-Date $mad).Date
}

# -----------------------------------------
#   HTML HEADER + SORTABLE TABLE SCRIPT
# -----------------------------------------

$htmlHeader = @"
<html>
<head>
<title>$($thedate.ToString('M/d/yyyy')) $tcusername Medication Administration Report</title>

<style>
body {
    font-family: Arial, sans-serif;
    margin: 20px;
    font-size: 16px;
}
h2 {
    border-bottom: 2px solid #444;
    padding-bottom: 4px;
}
table {
    border-collapse: collapse;
    width: 80%;
    margin-bottom: 25px;
    font-size: 12px;
}
th, td {
    border: 1px solid #999;
    padding: 6px;
    text-align: left;
}
th {
    background-color: #f2f2f2;
    cursor: pointer;
}
tr:nth-child(even) {
    background-color: #fafafa;
}
.signature-section {
margin-top: 30px;
text-align: center;
}
.signature-section img {
max-width: 600px;
height: auto;
}
.signature-label {
margin-top: 5px;
font-size: 12px;
color: #555;
}
</style>

<script>
function sortTable(tableId, colIndex) {
    var table = document.getElementById(tableId);
    var switching = true;
    var dir = "asc";
    var switchcount = 0;

    while (switching) {
        switching = false;
        var rows = table.rows;

        for (var i = 1; i < rows.length - 1; i++) {
            var shouldSwitch = false;

            var x = rows[i].getElementsByTagName("TD")[colIndex];
            var y = rows[i + 1].getElementsByTagName("TD")[colIndex];

            var xVal = x.innerText.toLowerCase();
            var yVal = y.innerText.toLowerCase();

            if (!isNaN(parseFloat(xVal)) && !isNaN(parseFloat(yVal))) {
                xVal = parseFloat(xVal);
                yVal = parseFloat(yVal);
            }

            if (dir == "asc" && xVal > yVal) {
                shouldSwitch = true;
                break;
            }
            if (dir == "desc" && xVal < yVal) {
                shouldSwitch = true;
                break;
            }
        }

        if (shouldSwitch) {
            rows[i].parentNode.insertBefore(rows[i + 1], rows[i]);
            switching = true;
            switchcount++;
        }
        else if (switchcount == 0 && dir == "asc") {
            dir = "desc";
            switching = true;
        }
    }
}
</script>

</head>
<body>
<h1>$mad $tcusername Medication Administration Report</h1>
"@

$htmlFooter = "</body></html>"

# -----------------------------------------
#   FUNCTION: Convert objects to sortable HTML table
# -----------------------------------------

function Convert-ToSortableHtmlTable {
    param(
        [string]$TableId,
        [array]$Data
    )

    if ($Data.Count -eq 0) {
        return "<p>No data found.</p>"
    }

    $cols = $Data[0].PSObject.Properties.Name

    $html = "<table id='$TableId'><thead><tr>"

    for ($i=0; $i -lt $cols.Count; $i++) {
        $html += "<th onclick='sortTable(`"$TableId`",$i)'>$($cols[$i])</th>"
    }

    $html += "</tr></thead><tbody>"

    foreach ($row in $Data) {
        $html += "<tr>"
            foreach ($col in $cols) {
                $value = $row.$col #Patient ID
            if ($col -eq "Patient Id" -and $value) {
        # Create clickable link
            $link = "https://adcrr.techcareehr.com/dashboard/patient?id=$value"
            $html += "<td><a href='$link' target='_blank'>$value</a></td>"
            }
            else {
        $html += "<td contenteditable='true'>$value</td>"
            }
        }
        $html += "</tr>"
    }

    $html += "</tbody></table>"
    return $html
}

#Base 64 signature begin:
$SignatureBase64 = @"
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
"@
#Base 64 signaure end:

# -----------------------------------------
#   BUILD HTML REPORT
# -----------------------------------------

$html = $htmlHeader

# --- Gabapentin Admin Report ---
$html += "<h2>Gabapentin Administration Report</h2>"
$gabData = $gabapentin | Sort-Object {[int]$_."Drug Strength"} |
    Select-Object "Patient Name","Patient Id","drug name","Drug Strength","quantity","Administration Date","UserName"
$html += Convert-ToSortableHtmlTable -TableId "gabapentinTable" -Data $gabData

# --- Gabapentin Waste ---
#$html += "<h3>Gabapentin Waste Summary</h3>"
$wasteRows = foreach ($s in $GabapentinWaste.Keys) {
    [PSCustomObject]@{
        Strength = $s
        Wasted   = $GabapentinWaste[$s]
    }
}
#$html += Convert-ToSortableHtmlTable -TableId "gabWaste" -Data $wasteRows

# --- Bupe 8-2 ---
$html += "<h2>Buprenorphine/Naloxone 8-2 mg Administration Report</h2>"
$bupeData = $bupe | Sort-Object "Patient Name" |
    Select-Object "Patient Name","Patient Id","drug name","Drug Strength","quantity","Administration Date","UserName"
$html += Convert-ToSortableHtmlTable -TableId "bupe82" -Data $bupeData

# --- Bupe 2-0.5 ---
$html += "<h2>Buprenorphine/Naloxone 2-0.5 mg Administration Report</h2>"
$bupeLowData = $bupeLow | Sort-Object "Patient Name" |
    Select-Object "Patient Name","Patient Id","drug name","Drug Strength","quantity","Administration Date","UserName"
$html += Convert-ToSortableHtmlTable -TableId "bupe205" -Data $bupeLowData

## --- Bupe Waste ---
#$html += "<h3>Buprenorphine/Naloxone Waste Summary</h3>"
#$bupeWasteRows = foreach ($s in $BupeWaste.Keys) {
#    [PSCustomObject]@{
#        Strength = $s
#        Wasted   = $BupeWaste[$s]
#    }
#}
#$html += Convert-ToSortableHtmlTable -TableId "bupeWaste" -Data $bupeWasteRows

# --- Inventory Summaries ---
$html += "<h2>Gabapentin Inventory Summary</h2>"
$gabCounts = $gabapentin |
    Group-Object {[int]$_."Drug Strength"} |
    ForEach-Object {
        $strength = [int]$_.Name   # <— FIX: force integer key
        $admin = ($_.Group | Measure-Object quantity -Sum).Sum
        $begin = $BeginCounts[$strength]
        $waste = $GabapentinWaste[$strength]
        $end = $begin - $admin - $waste

        [PSCustomObject]([ordered]@{
            "Strength"           = $strength
            "Begin Count"        = $begin
            "Total Administered" = $admin
            "Total Wasted"       = $waste
            "End Count"          = $end
        })
    }

$html += Convert-ToSortableHtmlTable -TableId "gabInventory" -Data $gabCounts

$html += "<h2>Buprenorphine/Naloxone Inventory Summary</h2>"
$bupeAll = $bupe + $bupeLow
$bupeCounts = $bupeAll |
    Group-Object "Drug Strength" |
    ForEach-Object {
        $strength = $_.Name
        $admin = ($_.Group | Measure-Object quantity -Sum).Sum
        $begin = $BupeBeginCounts[$strength]
        $waste = $BupeWaste[$strength]
        $end = $begin - $admin - $waste

        [PSCustomObject]([ordered]@{
            "Strength"           = $strength
            "Begin Count"        = $begin
            "Total Administered" = $admin
            "Total Wasted"       = $waste
            "End Count"          = $end
        })
    }
$html += Convert-ToSortableHtmlTable -TableId "bupeInventory" -Data $bupeCounts

# -----------------------------------------
# ELECTRONIC SIGNATURE For Robert Holland RN
# -----------------------------------------

$html += @"
<div class='signature-section'>
<h3>Signature</h3>
<img src='data:image/png;base64,$SignatureBase64' alt='Robert Holland Signature'>
<div class='signature-label'>
Robert Holland RN<br>
Generated: $(Get-Date)
</div>
</div>
"@

# -----------------------------------------
#   WRITE HTML FILE
# -----------------------------------------

$html += $htmlFooter
$html | Out-File $reportFile -Encoding UTF8

Start-Process $reportFile


## Filter for Pending Pharmacy Delivery and print list.
#$Results = Import-Csv -Path $dma | Where-Object {
#    $_.'Administration Type' -eq 'Pending Pharmacy Delivery' -and
#    $_.'UserName' -eq 'Robert Holland Registered Nurse'
#}

$Results = Import-Csv -Path $dma |
Where-Object {
$_.'Administration Type' -eq 'Pending Pharmacy Delivery' -and
#$_.'UserName' -eq 'Robert Holland Registered Nurse'
$_.'UserName' -eq $tcusername
} |
Sort-Object 'Patient Name', 'Drug Name'


# Create a print-friendly report
@(
    "Pending Pharmacy Delivery Report"
#    "User: Robert Holland Registered Nurse"
    "User: $tcusername"
    "Generated: $(Get-Date)"
    ("=" * 100)
    ""
    $Results | Format-Table `
        'Patient Name',
        'Patient Id',
        'Drug Name',
        'Drug Strength',
        'Current Housing Location'#,
        #'Administration Date',
        #'Provider' -AutoSize | Out-String
    ""
    "Total Records: $($Results.Count)"
) | Out-File -FilePath $TextFile -Encoding UTF8

Write-Host "Report saved to: $TextFile"

# Optional: Open the report in Notepad
notepad.exe $TextFile