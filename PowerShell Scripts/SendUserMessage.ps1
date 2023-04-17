# This script will create a popup window on the Logged In User's screen.
# This can be used to inform the user of something like "Please Restart your Compuer"

$messagetext = $args[0]
 
#region Import the Assemblies 
[void][reflection.assembly]::Load('System.Windows.Forms, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089') 
[void][reflection.assembly]::Load('System.Data, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089') 
[void][reflection.assembly]::Load('System.Drawing, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a') 
#endregion Import Assemblies 


#Embedded mindIT logo
#Use an online image-to-base64 converter
#This site works: https://codebeautify.org/image-to-base64-converter
#NOTE: Make sure the image is small or it will cover your text
$base64ImageString = "YOUR-BASE64-STRING-HERE"
$imageBytes = [Convert]::FromBase64String($base64ImageString)
$ms = New-Object IO.MemoryStream($imageBytes, 0, $imageBytes.Length)
$ms.Write($imageBytes, 0, $imageBytes.Length);
$img = [System.Drawing.Image]::FromStream($ms, $true)

$pictureBox = new-object Windows.Forms.PictureBox
$pictureBox.Width = $img.Size.Width
$pictureBox.Height = $img.Size.Height
$pictureBox.Image = $img
$pictureBox.Location = '105, 15'

#region Generated Form Objects 
[System.Windows.Forms.Application]::EnableVisualStyles() 
$MainForm = New-Object 'System.Windows.Forms.Form' 
$PanelMessage = New-Object 'System.Windows.Forms.Panel' 
$ButtonOK = New-Object 'System.Windows.Forms.Button' 
$LabelMessage = New-Object 'System.Windows.Forms.Label'
$InitialFormWindowState = New-Object 'System.Windows.Forms.FormWindowState' 
#endregion Generated Form Objects 

# User Generated Script 
$MainForm_Load = { 
    #TODO: Initialize Form Controls here
} 
$ButtonOK_Click = { 
    #TODO: Place custom script here 
    $MainForm.Close() 
}

$PanelMessage_Paint = [System.Windows.Forms.PaintEventHandler] { 
    #Event Argument: $_ = [System.Windows.Forms.PaintEventArgs] 
    #TODO: Place custom script here 

} 
 
#region Generated Events 
$Form_StateCorrection_Load = 
{ 
    #Correct the initial state of the form to prevent the .Net maximized form issue 
    $MainForm.WindowState = $InitialFormWindowState 
} 

$Form_StoreValues_Closing = 
{ 
    #Store the control values 
} 


$Form_Cleanup_FormClosed = 
{ 
    #Remove all event handlers from the controls 
    try { 
        $ButtonOK.remove_Click($buttonOK_Click)
        $PanelMessage.remove_Paint($PanelMessage_Paint)
        $MainForm.remove_Load($MainForm_Load) 
        $MainForm.remove_Load($Form_StateCorrection_Load) 
        $MainForm.remove_Closing($Form_StoreValues_Closing) 
        $MainForm.remove_FormClosed($Form_Cleanup_FormClosed) 
    }

    catch [Exception] 
    { } 
} 
#endregion Generated Events 
 
#region Generated Form Code 
$MainForm.SuspendLayout() 
$PanelMessage.SuspendLayout() 

# MainForm 
$MainForm.Controls.Add($pictureBox)
$MainForm.Controls.Add($PanelMessage) 
$MainForm.Controls.Add($LabelMessage) 
$MainForm.AutoScaleDimensions = '6, 13' 
$MainForm.AutoScaleMode = 'Font' 
$MainForm.BackColor = 'White'
$MainForm.FormBorderStyle = 'None'
$MainForm.ClientSize = '373, 400' 
$MainForm.MaximizeBox = $False 
$MainForm.MinimizeBox = $False 
$MainForm.Name = 'MainForm' 
$MainForm.ShowIcon = $False 
$MainForm.ShowInTaskbar = $False 
$MainForm.StartPosition = 'CenterScreen' 
$MainForm.TopMost = $True 
$MainForm.add_Load($MainForm_Load) 

# PanelMessage 
$PanelMessage.Controls.Add($ButtonOK)
$PanelMessage.BackColor = 'ScrollBar' 
$PanelMessage.Location = '0, 320' 
$PanelMessage.Name = 'PanelMessage' 
$PanelMessage.Size = '378, 80' 
$PanelMessage.TabIndex = 9 
$PanelMessage.add_Paint($PanelMessage_Paint) 

# ButtonOK 
$ButtonOK.Location = '150, 17' #254, 17
$ButtonOK.Name = 'ButtonOK' 
$ButtonOK.Size = '77, 52' 
$ButtonOK.TabIndex = 7 
$ButtonOK.Text = 'OK' 
$ButtonOK.UseVisualStyleBackColor = $True 
$ButtonOK.add_Click($ButtonOK_Click) 

# LabelMessage 
$LabelMessage.Font = 'Microsoft Sans Serif, 12pt' 
$LabelMessage.Location = '12, 84' 
$LabelMessage.Name = 'LabelMessage' 
$LabelMessage.Size = '350, 240' 
$LabelMessage.TabIndex = 2 
$LabelMessage.Text = "$messagetext"

$PanelMessage.ResumeLayout() 
$MainForm.ResumeLayout() 
#endregion Generated Form Code 

#Save the initial state of the form 
$InitialFormWindowState = $MainForm.WindowState 
#Init the OnLoad event to correct the initial state of the form 
$MainForm.add_Load($Form_StateCorrection_Load) 
#Clean up the control events 
$MainForm.add_FormClosed($Form_Cleanup_FormClosed) 
#Store the control values when form is closing 
$MainForm.add_Closing($Form_StoreValues_Closing) 
#Show the Form 
return $MainForm.ShowDialog()