
# ----------------------------------------------------------------------------
# Script Author: Robert Holland RN
# Script Name: pdma.ps1
# Creation Date: Thu Jun 04 2026 15:32:39 GMT-0700 (US Mountain Standard Time)
# Last Modified: 10/19/2026 17:27
# Copyright (c)2026
# Purpose: Parse the detailed medication administration .csv file and generate a Gabapentin and Suboxone report based on username.
# Purpose: Parse detailed medication administration CSV and generate
#          HTML report with sortable tables.
# ----------------------------------------------------------------------------

# -----------------------------------------
#   CONFIGURATION
# -----------------------------------------

# Enter date ONE time here
$thedate = Get-Date "09-23-2026"

# TechCare Username
$tcusername = "Robert Holland Registered Nurse"

#Suboxone beginning count:
    $SUB_2mg = 100
    $SUB_8mg = 3000

#Gabapentin beginning count:
    $G_100mg = 3000
    $G_300mg = 3000 
    $G_400mg = 3000
    $G_600mg = 3000
    $G_800mg = 3000

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
$dma = "$env:USERPROFILE/Downloads/detailed-medication-administrations-$($thedate.ToString('MM-dd-yyyy')).csv"
$TextFile = "$env:USERPROFILE\Downloads\PendingPharmacyDelivery-$($thedate.ToString('MM-dd-yyyy')).txt"

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
#printBtn {
    position: fixed;
    top: 10px;
    right: 10px;
    padding: 8px 15px;
    font-size: 14px;
    cursor: pointer;
    z-index: 1000;
}

@media print {

    @page {
        size: landscape;
        margin: 0.25in;
    }

    /* Hide print button */
    #printBtn {
        display: none;
    }

    body {
        margin: 0;
        font-size: 9px;
    }

    h1 {
        font-size: 12px;
        margin: 0 0 4px 0;
    }

    h2 {
        font-size: 10px;
        margin: 4px 0 2px 0;
        padding-bottom: 1px;
    }

    table {
        width: 100%;
        border-collapse: collapse;
        table-layout: auto;
        font-size: 8px;
        margin-bottom: 6px;
    }

    th, td {
        border: 1px solid #999;
        padding: 1px 2px;
        line-height: 1.0;
        white-space: nowrap;
    }

    a {
        color: black;
        text-decoration: none;
    }

    .signature-section {
        margin-top: 5px;
    }

    .signature-label {
        font-size: 8px;
    }
}

body {
    font-family: Arial, sans-serif;
    margin: 20px;
    font-size: 16px;
}
h2 {
    border-bottom: 2px solid #444;
    padding-bottom: 2px;
}
table {
    border-collapse: collapse;
    width: 80%;
    margin-bottom: 25px;
    font-size: 12px;
}
th, td {
    border: 1px solid #999;
    padding: 2px;
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
text-align: left;
}
.signature-section img {
max-width: 150px;
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

function printReport() {
    window.print();
}
</script>

</head>
<body>
<button id="printBtn" onclick="printReport()">
Print Report
</button>
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
iVBORw0KGgoAAAANSUhEUgAAAdQAAABcCAYAAADXs0RtAAAACXBIWXMAAB2HAAAdhwGP5fFlAAAA
B3RJTUUH6gsHARY12uWALwAAAAd0RVh0QXV0aG9yAKmuzEgAAAAMdEVYdERlc2NyaXB0aW9uABMJ
ISMAAAAKdEVYdENvcHlyaWdodACsD8w6AAAADnRFWHRDcmVhdGlvbiB0aW1lADX3DwkAAAAJdEVY
dFNvZnR3YXJlAF1w/zoAAAALdEVYdERpc2NsYWltZXIAt8C0jwAAAAh0RVh0V2FybmluZwDAG+aH
AAAAB3RFWHRTb3VyY2UA9f+D6wAAAAh0RVh0Q29tbWVudAD2zJa/AAAABnRFWHRUaXRsZQCo7tIn
AAABmElEQVR4nO3ZsQ3DMAwAwSizaWsNxwzg0g8YDu5KVuweBNfMzAcAuOX79AIA8A8EFQACggoA
AUEFgICgAkBAUAEgIKgAEBBUAAgIKgAEBBUAAoIKAAFBBYCAoAJAQFABICCoABAQVAAICCoABAQV
AAKCCgABQQWAgKACQEBQASAgqAAQEFQACAgqAAQEFQACggoAAUEFgICgAkBAUAEgIKgAEBBUAAgI
KgAEBBUAAoIKAAFBBYCAoAJAQFABICCoABAQVAAICCoABAQVAAKCCgABQQWAgKACQEBQASAgqAAQ
EFQACAgqAAQEFQACggoAAUEFgICgAkBAUAEgIKgAEBBUAAgIKgAEBBUAAoIKAAFBBYCAoAJAQFAB
ICCoABAQVAAICCoABAQVAAKCCgABQQWAgKACQEBQASAgqAAQEFQACAgqAAQEFQACggoAAUEFgICg
AkBAUAEgIKgAEFh773l6CQB4k3POZeZCBYCAoAJAQFABILBmxg8VAG5yoQJAQFABICCoABAQVAAI
CCoABAQVAAKCCgCBH7tlDKpHLi6rAAAAAElFTkSuQmCC
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
        $strength = [int]$_.Name   # <â€” FIX: force integer key
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
    } | Sort-Object Strength

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
    } | Sort-Object Strength

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

