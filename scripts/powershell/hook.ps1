#!/usr/bin/env pwsh
# Entry point for the de-speckit-extension hook command.
# Invoked as: hook.ps1 <event_name>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$EventName
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# TODO: implement the actual hook logic here.
# $EventName will be one of: before_constitution, before_specify,
# before_clarify, before_plan, before_tasks, before_implement,
# before_checklist, before_analyze, before_taskstoissues,
# after_constitution, after_specify, after_clarify, after_plan,
# after_tasks, after_implement, after_checklist, after_analyze,
# after_taskstoissues.

Write-Output "[de-speckit-extension] hook fired: $EventName (not yet implemented)"
