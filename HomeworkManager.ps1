<#        
    .SYNOPSIS
     GUI for managing homework assignments

    .DESCRIPTION
    The name, due date, and notes about each assignment are saved as a csv file. 

    .NOTES
    ========================================================================
         PowerShell Project Source Code 
         
         NAME: Homework Manager
         
         AUTHOR: Kevin Hood
         DATE  : 4/5/18
         
         COMMENT: 
         
    ==========================================================================
#>
#region Import the Assemblies
#----------------------------------------------
[void][reflection.assembly]::Load('mscorlib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089')
[void][reflection.assembly]::Load('System.Drawing, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a')
[void][reflection.assembly]::Load('System.Windows.Forms, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089')
#endregion Import Assemblies

#
# Create an assignment. 
#
function Add-Assignment($NewAssignment)
{
	$NameAvailable = $true
	foreach ($Item in $Script:AssignmentsArray)
	{
        
		if ($NewAssignment.Name -eq $Item.Name)
		{
			$NameAvailable = $false
		}
	}
	if ($NameAvailable)
	{
		$Script:AssignmentsArray.Add($NewAssignment)
		Refresh-AssignmentList
	}
}
#
#Reload the assignments 
#
function Refresh-AssignmentList
{
	$Assignments.Items.Clear()
	foreach ($Object in $Script:AssignmentsArray)
	{
		$Assignments.Items.Add(($Object.DueDate +" - "+$Object.Name))
	}
}
#
#Load assignments from a csv
#
function Import-Assignments
{
	$Script:HomeworkAssignmentsFile = Import-FileDialog
	if (Test-Path -Path $Script:HomeworkAssignmentsFile)
	{
		$CSV = Import-CSV -Path $Script:HomeworkAssignmentsFile
		foreach ($Item in $CSV)
		{
			
			$Assignment = New-Object -TypeName PSCustomObject
			$Assignment | Add-Member -MemberType NoteProperty -Name "Name" -Value $Item.Name
			$Assignment | Add-Member -MemberType NoteProperty -Name "DueDate" -Value $Item.DueDate
			$Assignment | Add-Member -MemberType NoteProperty -Name "Notes" -Value $Item.Notes
			
			$Script:AssignmentsArray.Add($Assignment)
		}
		Refresh-AssignmentList
	}
	
}
#
#Get file path of where you want to save the csv 
#
function SaveAs-File($initialDirectory)
{
	[System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
	$SaveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
	$SaveFileDialog.initialDirectory = $initialDirectory
	$SaveFileDialog.filter = "CSV File (*.CSV)|*.CSV"
	$SaveFileDialog.ShowDialog() | Out-Null
	if ($SaveFileDialog.FileName -eq $null)
	{
		return "C:\";
	}
	else
	{
		return $SaveFileDialog.filename
	}
}

#
#Export assignments to a csv. 
#
function Export-Assignments
{
	$FilePath = SaveAs-File -initialDirectory "C:\"
	if (!$FilePath -eq "C:\")
	{
		$Script:AssignmentsArray | Export-Csv -Path $FilePath
	}
}

#
#Get the file path of the homework assignments csv file. 
#
Function Import-FileDialog
{
	$ofn = New-Object System.Windows.Forms.OpenFileDialog
	$outer = New-Object System.Windows.Forms.Form
	$outer.StartPosition = [Windows.Forms.FormStartPosition] "Manual"
	$outer.Location = New-Object System.Drawing.Point -100, -100
	$ofn.InitialDirectory = 'C:\'
	$ofn.Filter = "CSV Files (*.CSV)|*.CSV"
	$outer.add_Shown({
			$outer.Activate();
			$ofn.ShowDialog($outer);
			$outer.Close();
		})
	$ofn.ShowDialog() | Out-Null
	return [String]$ofn.FileName
}

#
#Gets the directory of the original script or the .exe 
#
function get-scriptdirectory
{
	#Note: From Sapien Forums
	if ($hostinvocation -ne $null)
	{
		Split-Path $hostinvocation.MyCommand.path
	}
	else
	{
		$invocation = (Get-Variable MyInvocation -Scope 1).Value
		Split-Path $PSCommandPath
	}
}
#
#Get the path of the .exe or .ps1
#
function Get-ProgramLocation
{
	#Note: From Sapien Forums
	if ($hostinvocation -ne $null)
	{
		return $hostinvocation.MyCommand.path
	}
	else
	{
		return $PSCommandPath
	}
}


$HomeDirectory = get-scriptdirectory #Directory of the exe or script
$ProgramLocation = Get-ProgramLocation #File location of the exe or script
$Script:HomeworkAssignmentsFile = ""; #Path to the assignments csv file
$Script:AssignmentsArray = New-Object System.Collections.Arraylist #Array of all the assignments. 
$ResY = ([System.Windows.Forms.Screen]::PrimaryScreen).workingarea.Height

#
#initialize the controls
#
$App = New-Object System.Windows.Forms.Form
$Assignments = New-Object System.Windows.Forms.ListBox
$NotesLabel = New-Object System.Windows.Forms.Label
$NotesTextbox = New-Object System.Windows.Forms.TextBox
$DueDateTimePicker = New-Object System.Windows.Forms.DateTimePicker
$DueDateLabel = New-Object System.Windows.Forms.Label
$MonthCalender = New-Object System.Windows.Forms.MonthCalendar
$HomeworkTextbox = New-Object System.Windows.Forms.TextBox
$HomeWorkTitleLabel = New-Object System.Windows.Forms.Label
$AddHomeworkButton = New-Object System.Windows.Forms.Button
$RemoveHomeworkButton = New-Object System.Windows.Forms.Button
$UpdateHomeworkButton = New-Object System.Windows.Forms.Button
$MS_Main = New-Object System.Windows.Forms.MenuStrip
$Import = new-object System.Windows.Forms.ToolStripMenuItem
$Export = new-object System.Windows.Forms.ToolStripMenuItem
$Clear = new-object System.Windows.Forms.ToolStripMenuItem

#
#Add the controls to the main app
#
$App.Controls.Add($Assignments)
$App.Controls.Add($NotesLabel)
$App.Controls.Add($NotesTextbox)
$App.Controls.Add($DueDateTimePicker)
$App.Controls.Add($DueDateLabel)
$App.Controls.Add($MonthCalender)
$App.Controls.Add($HomeworkTextbox)
$App.Controls.Add($HomeWorkTitleLabel)

#Set the properties for the App. 
$App.Name = 'App'
$App.MaximizeBox = $true
$App.StartPosition = 'Centerscreen'
$App.Size = New-Object System.Drawing.Size(($ResY * (4/3)), $ResY);
$App.AutoScroll = $true
$App.TopMost = $false
$App.BackColor = [System.Drawing.Color]::White
$App.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($ProgramLocation)
$App.Text = 'Homework Manager'
$App.add_Load($App_Load)
$App.WindowState = [System.Windows.Forms.FormWindowState]::Maximized #Start full screened


#
#Menu Strip, top controls
#
$MS_Main.Items.AddRange(@($Import, $Export, $Clear))
$MS_Main.Location = new-object System.Drawing.Point(0, 0)
$MS_Main.Name = "MS_Main"
$MS_Main.Size = New-Object System.Drawing.Size($App.Width, 24)
$MS_Main.TabIndex = 0
$MS_Main.Text = "menuStrip1"


#
#Import control for importing the csv
#
$Import.Name = "Import"
$Import.Size = new-object System.Drawing.Size(35, 20)
$Import.Text = "&Import"
$Import.Add_Click({ Import-Assignments })
#
#Export the assignments to a csv. 
#
$Export.Name = "Export"
$Export.Size = new-object System.Drawing.Size(51, 20)
$Export.Text = "&Export"
$Export.Add_Click({
		$Script:AssignmentsArray | Export-Csv -Path (SaveAs-File)
	})

$Clear.Name = "New";
$Clear.Size = new-object System.Drawing.Size(51, 20);
$Clear.Text = "&New";
$Clear.Add_Click({
		$NotesTextbox.Text = "";
		$HomeworkTextbox.Text = "";
		$DueDateTimePicker.ResetText()
		$Assignments.ClearSelected()
	})

$App.MainMenuStrip = $MS_Main
$App.Controls.Add($MS_Main)

#
#Selected Assignment Changed 
#

$FocusedAssignment = {
	foreach ($Item in $Script:AssignmentsArray)
	{
        $SelectedItemName = ($Assignments.SelectedItem.ToString()).Substring(($Assignments.SelectedItem.ToString().IndexOf('-')+2),($Assignments.SelectedItem.ToString().Length - ($Assignments.SelectedItem.ToString().IndexOf('-')+2)))
		if ($Item.Name -eq $SelectedItemName)
		{
			$HomeworkTextbox.Text = $Item.Name
			$DueDateTimePicker.Value = $Item.DueDate
			$NotesTextbox.Text = $Item.Notes
		}
	}
}


#
# Assignments
#
$Assignments.Location = New-Object System.Drawing.Size(((0/(728 * (4/3))) * $App.Width), ((400/728) * $App.Height))
$Assignments.Name = 'Assignments'
$Assignments.Size = New-Object System.Drawing.Size(($App.Width), (($App.Height) - $Assignments.Location.Y))
$Assignments.Dock = [System.Windows.Forms.DockStyle]::Bottom
$Assignments.IntegralHeight = $false
$Assignments.TabIndex = 7
$Assignments.Font = New-Object System.Drawing.Font("Calibri", 15, [System.Drawing.FontStyle]::Regular)
$Assignments.Add_Click($FocusedAssignment);
$Assignments.Add_SelectedValueChanged($FocusedAssignment);
$Assignments.Sorted = $true
#
#Add Homework Button
#
$AddHomeworkButton = New-Object System.Windows.Forms.Button
$AddHomeworkButton.Location = New-Object System.Drawing.Size(((43/(728 * (4/3))) * $App.Width), ((315/728) * $App.Height))
$AddHomeworkButton.Size = New-Object System.Drawing.Size(((120/(728 * (4/3))) * $App.Width), ((25/728) * $App.Height))
$AddHomeworkButton.Text = "Add Assignment"
$AddHomeworkButton.BackColor = "White"
$AddHomeworkButton.Add_Click({
		$Date = $DueDateTimePicker.Value.Month.ToString() + "/" + $DueDateTimePicker.Value.Day.ToString() + "/" + $DueDateTimePicker.Value.Year.ToString()
		$Assignment = New-Object -TypeName PSCustomObject
		$Assignment | Add-Member -MemberType NoteProperty -Name "Name" -Value $HomeworkTextbox.Text
		$Assignment | Add-Member -MemberType NoteProperty -Name "DueDate" -Value $Date
		$Assignment | Add-Member -MemberType NoteProperty -Name "Notes" -Value $NotesTextbox.Text
		Add-Assignment -NewAssignment $Assignment
	});
$App.Controls.Add($AddHomeworkButton)

#
#Update Homework Button
#
$UpdateHomeworkButton = New-Object System.Windows.Forms.Button
$UpdateHomeworkButton.Location = New-Object System.Drawing.Size(((163/(728 * (4/3))) * $App.Width), ((315/728) * $App.Height))
$UpdateHomeworkButton.Size = New-Object System.Drawing.Size(((120/(728 * (4/3))) * $App.Width), ((25/728) * $App.Height))
$UpdateHomeworkButton.Text = "Update Assignment"
$UpdateHomeworkButton.BackColor = "White"
$UpdateHomeworkButton.Add_Click({
		for ($i = 0; $i -le $Script:AssignmentsArray.Count; $i++)
		{
			if ($Script:AssignmentsArray[$i].Name -eq $HomeworkTextbox.Text)
			{
				$Date = $DueDateTimePicker.Value.Month.ToString() + "/" + $DueDateTimePicker.Value.Day.ToString() + "/" + $DueDateTimePicker.Value.Year.ToString()
				$Script:AssignmentsArray[$i].Name = $HomeworkTextbox.Text
				$Script:AssignmentsArray[$i].Duedate = $Date
				$Script:AssignmentsArray[$i].Notes = $NotesTextbox.Text
			}
		}
		Refresh-AssignmentList
		
		
	});
$App.Controls.Add($UpdateHomeworkButton)

#
#Remove Homework Button
#
$RemoveHomeworkButton = New-Object System.Windows.Forms.Button
$RemoveHomeworkButton.Location = New-Object System.Drawing.Size(((283/(728 * (4/3))) * $App.Width), ((315/728) * $App.Height))
$RemoveHomeworkButton.Size = New-Object System.Drawing.Size(((120/(728 * (4/3))) * $App.Width), ((25/728) * $App.Height))
$RemoveHomeworkButton.Text = "Remove Assignment"
$RemoveHomeworkButton.BackColor = "White"
$RemoveHomeworkButton.Add_Click({
		for ($i = 0; $i -le $Script:AssignmentsArray.Count; $i++)
		{
			if ($Script:AssignmentsArray[$i].Name.equals($HomeworkTextbox.Text))
			{
				$Script:AssignmentsArray.RemoveAt($i)
			}
		}
		Refresh-AssignmentList
	});
$App.Controls.Add($RemoveHomeworkButton)




#
# NotesLabel
#
$NotesLabel.AutoSize = $True
$NotesLabel.Location = New-Object System.Drawing.Size(((43/(728 * (4/3))) * $App.Width), ((152/728) * $App.Height))
$NotesLabel.Name = 'NotesLabel'
$NotesLabel.Font = New-Object System.Drawing.Font("Calibri", 15, [System.Drawing.FontStyle]::Regular)
$NotesLabel.Size = New-Object System.Drawing.Size(((41/(728 * (4/3))) * $App.Width), ((13/728) * $App.Height))
$NotesLabel.TabIndex = 6
$NotesLabel.Text = 'Notes: '
$NotesLabel.add_Click($NotesLabel_Click)
#
# NotesTextbox
#
$NotesTextbox.Location = New-Object System.Drawing.Size(((43/(728 * (4/3))) * $App.Width), ((185/728) * $App.Height))
$NotesTextbox.Multiline = $True
$NotesTextbox.Name = 'NotesTextbox'
$NotesTextbox.ScrollBars = 'Both'
$NotesTextbox.Font = New-Object System.Drawing.Font("Calibri", 14, [System.Drawing.FontStyle]::Regular)
$NotesTextbox.Size = New-Object System.Drawing.Size(((500/(728 * (4/3))) * $App.Width), ((124/728) * $App.Height))
$NotesTextbox.TabIndex = 5
$NotesTextbox.add_TextChanged($NotesTextbox_TextChanged)
#
# DueDateTimePicker
#
$DueDateTimePicker.Location = New-Object System.Drawing.Size(((43/(728 * (4/3))) * $App.Width), ((114/728) * $App.Height))
$DueDateTimePicker.Name = 'DueDateTimePicker'
$DueDateTimePicker.Font = New-Object System.Drawing.Font("Calibri", 14, [System.Drawing.FontStyle]::Regular)
$DueDateTimePicker.Size = New-Object System.Drawing.Size(((400/(728 * (4/3))) * $App.Width), ((20/728) * $App.Height))
$DueDateTimePicker.TabIndex = 4
#
# DueDateLabel
#
$DueDateLabel.AutoSize = $True
$DueDateLabel.Location = New-Object System.Drawing.Size(((43/(728 * (4/3))) * $App.Width), ((91/728) * $App.Height))
$DueDateLabel.Name = 'DueDateLabel'
$DueDateLabel.Size = New-Object System.Drawing.Size(((56/(728 * (4/3))) * $App.Width), ((13/728) * $App.Height))
$DueDateLabel.TabIndex = 3
$DueDateLabel.Font = New-Object System.Drawing.Font("Calibri", 15, [System.Drawing.FontStyle]::Regular)
$DueDateLabel.Text = 'Due Date:'
$DueDateLabel.add_Click($DueDateLabel_Click)
#
# MonthCalender
#
$MonthCalender.Location = New-Object System.Drawing.Size(((682/(728 * (4/3))) * $App.Width), ((46/728) * $App.Height))
$MonthCalender.Name = 'MonthCalender'
$MonthCalender.TabIndex = 2
#
# HomeworkTextbox
#
$HomeworkTextbox.Location = New-Object System.Drawing.Size(((43/(728 * (4/3))) * $App.Width), ((52/728) * $App.Height))
$HomeworkTextbox.Name = 'HomeworkTextbox'
$HomeworkTextbox.Font = New-Object System.Drawing.Font("Calibri", 14, [System.Drawing.FontStyle]::Regular)
$HomeworkTextbox.Size = New-Object System.Drawing.Size(((500/(728 * (4/3))) * $App.Width), ((20/728) * $App.Height))
$HomeworkTextbox.TabIndex = 1
#
# HomeWorkTitleLabel
#
$HomeWorkTitleLabel.AutoSize = $True
$HomeWorkTitleLabel.Location = New-Object System.Drawing.Size(((43/(728 * (4/3))) * $App.Width), ((29/728) * $App.Height))
$HomeWorkTitleLabel.Name = 'HomeWorkTitleLabel'
$HomeWorkTitleLabel.Font = New-Object System.Drawing.Font("Calibri", 15, [System.Drawing.FontStyle]::Regular)
$HomeWorkTitleLabel.Size = New-Object System.Drawing.Size(((87/(728 * (4/3))) * $App.Width), ((13/728) * $App.Height))
$HomeWorkTitleLabel.TabIndex = 0
$HomeWorkTitleLabel.Text = 'Homework Title: '

$App.ShowDialog() | Out-Null #Display the application. 
