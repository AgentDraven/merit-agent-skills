param()
$inputText = [Console]::In.ReadToEnd()
$message = 'MERIT completion boundary: before ending this task, run merit.ps1 law closeout, then merit.ps1 closeout --path <repo> --validate-only. Release closeout is explicit: merit.ps1 closeout --path <repo>. End with 3-3: Done, State, Next. Explicit exceptions: WIP, local-only, or no-commit.'
@{ followup_message = $message } | ConvertTo-Json -Compress
