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

# Detailed Medication Administration filename
$dma = "detailed-medication-administrations-06-01-2026.csv"

# Medication Administration Date
$mad = "6/1/2026"

# TechCare Username
$tcusername = "Robert Holland Registered Nurse"

# Create timestamped log filename
$timestamp = (Get-Date).ToString("yyyy-MM-dd_HHmmss")
$reportFile = "final_medication_report_$timestamp.html"

# Import CSV
$data = Import-Csv $dma

# -----------------------------------------
#   BEGINNING INVENTORY COUNTS
# -----------------------------------------

# Gabapentin beginning counts
$BeginCounts = @{
    100 = 5000
    300 = 3000
    400 = 2000
    600 = 1500
    800 = 1000
}

# Buprenorphine/Naloxone beginning counts
$BupeBeginCounts = @{
    "8-2"   = 1200
    "2-0.5" = 1300
}

$GabapentinWaste = @{
    100 = 0
    300 = 0
    400 = 0
    600 = 0
    800 = 0
}

$BupeWaste = @{
    "8-2"   = 0
    "2-0.5" = 0
}

# -----------------------------------------
#   FILTER: GABAPENTIN
# -----------------------------------------

$gabapentin = $data | Where-Object {
    $_."UserName" -like $tcusername -and
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
    $_."Drug Strength" -eq "8-2" -and
    ([datetime]$_."Administration Date").Date -eq (Get-Date $mad).Date
}

# -----------------------------------------
#   FILTER: BUPRENORPHINE/NALOXONE (2-0.5)
# -----------------------------------------
$bupeLow = $data | Where-Object {
    $_."UserName" -like $tcusername -and
    $_."drug name" -eq "Buprenorphine HCl-Naloxone HCl Sublingual" -and
    $_."Drug Strength" -eq "2-0.5" -and
    ([datetime]$_."Administration Date").Date -eq (Get-Date $mad).Date
}

# -----------------------------------------
#   HTML HEADER + SORTABLE TABLE SCRIPT
# -----------------------------------------

$htmlHeader = @"
<html>
<head>
<title>Medication Administration Report</title>

<style>
body {
    font-family: Arial, sans-serif;
    margin: 20px;
}
h2 {
    border-bottom: 2px solid #444;
    padding-bottom: 4px;
}
table {
    border-collapse: collapse;
    width: 100%;
    margin-bottom: 25px;
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
<h1>$tcusername Medication Administration Report</h1>
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
        $html += "<td>$value</td>"
            }
        }
        $html += "</tr>"
    }

    $html += "</tbody></table>"
    return $html
}

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
$html += "<h3>Gabapentin Waste Summary</h3>"
$wasteRows = foreach ($s in $GabapentinWaste.Keys) {
    [PSCustomObject]@{
        Strength = $s
        Wasted   = $GabapentinWaste[$s]
    }
}
$html += Convert-ToSortableHtmlTable -TableId "gabWaste" -Data $wasteRows

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

# --- Bupe Waste ---
$html += "<h3>Buprenorphine/Naloxone Waste Summary</h3>"
$bupeWasteRows = foreach ($s in $BupeWaste.Keys) {
    [PSCustomObject]@{
        Strength = $s
        Wasted   = $BupeWaste[$s]
    }
}
$html += Convert-ToSortableHtmlTable -TableId "bupeWaste" -Data $bupeWasteRows

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
#   WRITE HTML FILE
# -----------------------------------------

$html += $htmlFooter
$html | Out-File $reportFile -Encoding UTF8

Start-Process $reportFile