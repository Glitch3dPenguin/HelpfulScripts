# After this script runs, the report file can be found in the logged in user's home diectory 
# as .report.html

<#
.SYNOPSIS
    Update group policies and see that they are applied properly.
#>

gpupdate /force
gpresult /h "report.html" /f