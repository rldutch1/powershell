@echo off
REM ----------------------------------------------------------------------------
REM Author: Robert Holland
REM Name:
REM Creation Date: Tue Nov 10 2015 13:25:35 GMT-0700 (US Mountain Standard Time)
REM Last Modified:
REM Copyright (c)2015
REM Purpose:
REM ----------------------------------------------------------------------------
REM
REM ENTggCTXCernerCaseTracking
REM
REM #Add-DistributionGroupMember -Identity "GroupName" -Member "user@example.com"
REM
REM   EXAMPLE 1:
REM  www.sivarajan.com
REM  Add User to a Group - PowerShell Script
REM
REM Import-module ActiveDirectory
REM Import-CSV "Users.csv" | % {
REM Add-ADGroupMember -Identity TestGroup1 -Member $_.UserName
REM }
REM
REM   EXAMPLE 2:
REM Other option is to define a variable with your group name.
REM
REM Import-module ActiveDirectory
REM $GroupName = "BR-Systems Support"
REM Import-CSV "C:\Scripts\Users.csv" | % {
REM Add-ADGroupMember -Identity $GroupName -Member $_.UserName
REM }
REM
REM  In Practice
REM  www.sivarajan.com
REM  Add User to a Group - PowerShell Script
REM
REM Import-module ActiveDirectory
REM Import-CSV "Users.csv" | % {
REM Add-ADGroupMember -Identity ENTggCTXCernerCaseTracking -Member $_.UserName
REM }

Import-module -Name ActiveDirectory
Import-CSV -Path "C:\Scripts\Users.csv" | % {
Add-ADGroupMember -Identity TestGroup1 -Member $_.UserName
}
