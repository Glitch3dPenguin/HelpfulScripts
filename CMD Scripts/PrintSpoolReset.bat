echo Stopping print spooler
net stop spooler
echo Setting spooler failure options
sc failure spooler actions= restart/60000/restart/60000// reset= 240
echo Resetting spooler dependencies
sc config spooler depend= RPCSS
echo Deleting old print jobs
del /Q /F /S "%systemroot%\System32\Spool\Printers\*.*"
echo Starting print spooler
net start spooler