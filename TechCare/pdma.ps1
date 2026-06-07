# ----------------------------------------------------------------------------
# Script Author: Robert Holland 
# Script Name: 
# Creation Date: Thu Jun 04 2026 15:32:39 GMT-0700 (US Mountain Standard Time)
# Last Modified: 
# Copyright (c)2026
# Purpose: Parse the detailed medication administration .csv file and generate a Gabapentin and Suboxone report based on username.
# pdma - parse detailed medication administration.
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
$reportFile = "final_medication_report_$timestamp.log"

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


# -----------------------------------------
#   FILTER: GABAPENTIN
# -----------------------------------------
$gabapentin = $data |
Where-Object {
    $_."UserName" -like $tcusername -and
    $_."drug name" -eq "Gabapentin Oral" -and
    ([int]$_."Drug Strength") -in 100,300,400,600,800 -and
    ([datetime]$_."Administration Date").Date -eq (Get-Date $mad).Date
}


# -----------------------------------------
#   FILTER: BUPRENORPHINE/NALOXONE (8-2)
# -----------------------------------------
$bupe = $data |
Where-Object {
    $_."UserName" -like $tcusername -and
    $_."drug name" -eq "Buprenorphine HCl-Naloxone HCl Sublingual" -and
    $_."Drug Strength" -eq "8-2" -and
    ([datetime]$_."Administration Date").Date -eq (Get-Date $mad).Date
}

# -----------------------------------------
#   FILTER: BUPRENORPHINE/NALOXONE (2-0.5)
# -----------------------------------------
$bupeLow = $data |
Where-Object {
    $_."UserName" -like $tcusername -and
    $_."drug name" -eq "Buprenorphine HCl-Naloxone HCl Sublingual" -and
    $_."Drug Strength" -eq "2-0.5" -and
    ([datetime]$_."Administration Date").Date -eq (Get-Date $mad).Date
}

# -----------------------------------------
#   EXPORT COMBINED CSV
# -----------------------------------------

$allFiltered = $gabapentin + $bupe + $bupeLow
$allFiltered | Export-Csv "filtered_output.csv" -NoTypeInformation


# -----------------------------------------
#   WRITE HEADER TO LOG FILE
# -----------------------------------------
$now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
"Medication Report ($now)" | Out-File $reportFile
"======================================" | Out-File $reportFile -Append
"" | Out-File $reportFile -Append

# -----------------------------------------
#   GABAPENTIN REPORT (SORTED)
# -----------------------------------------
"Gabapentin Administration Report" | Out-File $reportFile -Append
"--------------------------------" | Out-File $reportFile -Append

$gabapentin |
Sort-Object @{ Expression = { [int]$_."Drug Strength" } ; Ascending = $true } |
Select-Object "Patient Name", "Patient Id", "drug name", "Drug Strength", quantity, "Administration Date", UserName |
Format-Table -AutoSize | Out-String | Out-File $reportFile -Append

# -----------------------------------------
#   GABAPENTIN INVENTORY
# -----------------------------------------

$gabCounts = $gabapentin |
Group-Object -Property { [int]$_."Drug Strength" } |
ForEach-Object {
    [PSCustomObject]@{
        Strength = $_.Name
        TotalQuantity = ($_.Group | Measure-Object -Property quantity -Sum).Sum
    }
} |
Sort-Object Strength

$inventory = foreach ($item in $gabCounts) {
    $strength = [int]$item.Strength
    $begin    = $BeginCounts[$strength]
    $total    = [int]$item.TotalQuantity
    $end      = $begin - $total

    [PSCustomObject]@{
        "Gabapentin Strength"          = $strength
        "Begin Count"                  = $begin
        "Total Quantity Administered"  = $total
        "End Count"                    = $end
    }
}

"Gabapentin Inventory Summary" | Out-File $reportFile -Append
"------------------------------" | Out-File $reportFile -Append
$inventory | Format-Table -AutoSize | Out-String | Out-File $reportFile -Append


# ---------------------------------------
#   BUPRENORPHINE/NALOXONE 8-2 mg SECTION
# ---------------------------------------
"`nBuprenorphine/Naloxone 8-2 mg Administration Report" | Out-File $reportFile -Append
"-----------------------------------------------------" | Out-File $reportFile -Append

if ($bupe.Count -gt 0) {
    $bupe |
    Select-Object "Patient Name", "Patient Id", "drug name", "Drug Strength", quantity, "Administration Date", UserName |
    Format-Table -AutoSize | Out-String | Out-File $reportFile -Append

    $bupeTotal = ($bupe | Measure-Object -Property quantity -Sum).Sum
    "Total Quantity Administered (8-2): $bupeTotal" | Out-File $reportFile -Append
}
else {
    "No administrations found." | Out-File $reportFile -Append
}

# -----------------------------------------
#   BUPRENORPHINE/NALOXONE 2-0.5 mg SECTION
# -----------------------------------------
"`nBuprenorphine/Naloxone 2-0.5 mg Administration Report" | Out-File $reportFile -Append
"--------------------------------------------------------" | Out-File $reportFile -Append

if ($bupeLow.Count -gt 0) {
    $bupeLow |
    Select-Object "Patient Name", "Patient Id", "drug name", "Drug Strength", quantity, "Administration Date", UserName |
    Format-Table -AutoSize | Out-String | Out-File $reportFile -Append

    $bupeLowTotal = ($bupeLow | Measure-Object -Property quantity -Sum).Sum
    "Total Quantity Administered (2-0.5): $bupeLowTotal" | Out-File $reportFile -Append
}
else {
    "No administrations found." | Out-File $reportFile -Append
}


# -----------------------------------------
#   BUPRENORPHINE INVENTORY (BOTH STRENGTHS)
# -----------------------------------------
$bupeAll = $bupe + $bupeLow

$bupeCounts = $bupeAll |
Group-Object -Property { $_."Drug Strength" } |
ForEach-Object {
    [PSCustomObject]@{
        Strength      = $_.Name
        TotalQuantity = ($_.Group | Measure-Object -Property quantity -Sum).Sum
    }
} |
Sort-Object Strength

$bupeInventory = foreach ($item in $bupeCounts) {
    $strength = $item.Strength
    $begin    = $BupeBeginCounts[$strength]
    $total    = [int]$item.TotalQuantity
    $end      = $begin - $total

    [PSCustomObject]@{
        "Buprenorphine Strength"       = $strength
        "Begin Count"                  = $begin
        "Total Quantity Administered"  = $total
        "End Count"                    = $end
    }
}

"`nBuprenorphine/Naloxone Inventory Summary" | Out-File $reportFile -Append
"------------------------------------------" | Out-File $reportFile -Append
$bupeInventory | Format-Table -AutoSize | Out-String | Out-File $reportFile -Append


# -----------------------------------------
#   OPEN LOG FILE IN NOTEPAD
# -----------------------------------------
Start-Process notepad.exe $reportFile
