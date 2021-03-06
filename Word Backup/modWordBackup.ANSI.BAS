'====================================================================
' AJPapps - Word backup [ANSI]
' Линда Кайе 2016. Посвящается Ариэль
' 
' Этот макрос создаёт резервную копию файла перед каждым 
' сохранением. Для этого пользователем определяется каталог для 
' бэкапов, в котором создаются подкаталоги с оптимизированным полным 
' именем сохраняемого файла, в которые, в свою очередь, копируются 
' файлы с датой и временем сохранения.
' 
' Например!
' 
' Каталог: E:\Backups
' Файл:    A:\Data\Jun-2016.DOC
' Бэкап:   E:\Backups\A~~Data~Jun-2016.DOC\2016-09-12 16-34-52.BAK
' 
' Каталог для бэкапов определяется через константу BACKUP_PATH.
' 
' В ANSI версии макроса желательно, чтобы путь к нему был как можно 
' короче, поскольку в Windows существует ограничение на 260 символов 
' для полного имени файла.
' 
' В UNICODE версии макроса можно использовать специальную форму 
' записи, чтобы гарантировать сохранение всех файлов:
' 
' • "C:\Backups" ==> "\\?\C:\Backups"
' • "\\MIDORI\Backups" ==> "\\?\UNC\MIDORI\Backups"
' 
' Макрос добавляется в модуль ThisDocument шаблона Normal.dot. Если 
' события Document_New() и Document_Open() уже определены, 
' соответствующий код добавляется куда-нибудь в их тело.
' 
' UNICODE версия макроса не работает в Windows 9x.
' 
' Внимание! Из-за особенностей Word, данный код не будет работать 
' с документом по умолчанию, который создаётся сразу же при запуске 
' программы. Он сработает с документами, которые были открыты, либо 
' были созданы через меню "Файл".
' 
' • 16.09.2016
'   Первый публичный релиз.
' 
'====================================================================
' 1. Программа распространяется бесплатно.
' 2. Вы имеете право распространять её на тех же условиях.
' 3. При распространении вы не имеете права менять авторство 
'    программы, присваивать его себе или каким-либо иным способом 
'    искажать его.
' 4. Разрешено коммерческое использование программы (в офисе, 
'    на производстве) за исключением её платного распространения 
'    или сдачи в аренду.
' 5. Программа распространяется как есть. Автор не несёт 
'    ответственности за любые трагедии или несчастные случаи, 
'    вызванные использованием программы.
' 6. Вы имеете право использовать ActiveX компоненты, поставляемые 
'    с программой, в собственных программах. При этом автор 
'    не гарантирует совместимость будущих версий компонентов.
' 7. Для любого пункта данного соглашения может быть сделано 
'    исключение с разрешения автора программы.
' 8. По любым вопросам, связанным с данной программой, обращайтесь 
'    по адресу lindaoneesama@gmail.com
' 
' Загружено с http://purl.oclc.org/Linda_Kaioh/Homepage/
'====================================================================
Option Explicit

Dim WithEvents DocEvents As Application

' Этот каталог можно переопределить. Желательно чтобы он был как
' можно короче. Или же в UNICODE можно использовать вариант записи
' "\\?\C:\Backups" или "\\?\UNC\MIDORI\Backups".
Const BACKUP_PATH = "D:\Word Backups"

'====================================================================
Private Sub Document_New()
  Set DocEvents = Application
End Sub

Private Sub Document_Open()
  Set DocEvents = Application
End Sub

'====================================================================
Private Sub DocEvents_DocumentBeforeSave(ByVal Doc As Document, _
                                         SaveAsUI As Boolean, _
                                         Cancel As Boolean)
  Dim BackupPath As String
  Dim Buff() As Byte
  
  On Error Resume Next
  
  ' Хитрость. Если файл только что создан, то нам его бэкапить как
  ' раз и не надо. Его не существует.
  If Not IsFileExist(Doc.FullName) Then Exit Sub
  
  BackupPath = BACKUP_PATH
  
  If Not IsDirExist(BackupPath) Then MakeDir BackupPath
  If Err Then
    ErrorDisplay Err, BackupPath & vbCrLf & vbCrLf & _
                      "Can't create backup folder."
    Exit Sub
  End If
  
  If Right(BackupPath, 1) <> "\" Then BackupPath = BackupPath & "\"
  BackupPath = BackupPath & Replace( _
                                Replace( _
                                    Replace(Doc.FullName, "/", "~"), _
                                "\", "~"), _
                            ":", "~")
  
  If Not IsDirExist(BackupPath) Then MakeDir BackupPath
  If Err Then
    ErrorDisplay Err, BackupPath & vbCrLf & vbCrLf & _
                      "Can't create backup folder."
    Exit Sub
  End If
  
  If Right(BackupPath, 1) <> "\" Then BackupPath = BackupPath & "\"
  BackupPath = BackupPath & Format(Now, "yyyy\-mm\-dd hh\-nn\-ss") & ".BAK"
  
  ' Магия. CopyFile пытается открыть файл с записью (нафига?),
  ' поэтому ничего у него не получается. Поэтому сделаем вот
  ' так: сами прочитаем и сами сохраним...
  Buff = GetFileB(Doc.FullName, True)
  If Err Then
    ErrorDisplay Err, Doc.FullName & vbCrLf & vbCrLf & _
                      "Can't read source file." & _
                      vbCrLf & vbCrLf & BackupPath
    Exit Sub
  End If
  
  PutFileB BackupPath, Buff, True
  If Err Then
    ErrorDisplay Err, BackupPath & vbCrLf & vbCrLf & _
                      "Can't write file to backup location." & _
                      vbCrLf & vbCrLf & BackupPath
  End If
End Sub

'====================================================================
Private Function IsDirExist(ByVal Path As String) As Boolean
  Dim TXT As String
  
  On Error Resume Next
  
  TXT = Dir(Path, vbArchive + vbDirectory + vbHidden + _
                  vbNormal + vbReadOnly + vbSystem)
  IsDirExist = CBool(TXT <> "")
End Function

Private Function IsFileExist(ByVal Path As String) As Boolean
  Dim TXT As String
  
  On Error Resume Next
  
  TXT = Dir(Path, vbArchive + vbHidden + _
                  vbNormal + vbReadOnly + vbSystem)
  IsFileExist = CBool(TXT <> "")
End Function

'====================================================================
Public Function GetFileB(ByVal FileName As String, _
                         ByVal RaiseErrors As Boolean) As Byte()
  Dim hFile As Long
  
  On Error GoTo hError
  
  If Not IsFileExist(FileName) Then Err.Raise 53
  
  hFile = FreeFile
  Open FileName For Binary Access Read As #hFile
  
  ReDim GetFileB(0 To LOF(hFile) - 1)
  If LOF(hFile) > 0 Then Get #hFile, , GetFileB
  
  Close #hFile
  Exit Function
  
hError:
  If hFile > 0 Then Close #hFile
  Err.Raise Err.Number, Err.Source, Err.Description
End Function

Public Sub PutFileB(ByVal FileName As String, _
                    ByRef Data() As Byte, _
                    ByVal RaiseErrors As Boolean)
  Dim hFile As Long
  
  On Error GoTo hError
  
  If IsFileExist(FileName) Then Kill FileName
  
  hFile = FreeFile
  Open FileName For Binary Access Write As #hFile
  
  Put #hFile, , Data
  
  Close #hFile
  Exit Sub
  
hError:
  If hFile > 0 Then Close #hFile
  Err.Raise Err.Number, Err.Source, Err.Description
End Sub

'====================================================================
Public Sub MakeDir(ByVal Path As String)
  MkDir Path
End Sub

'====================================================================
Public Sub ErrorDisplay(ByVal ErrX As ErrObject, _
                        Optional ByVal Message As String = "Something happens.")
  Dim TXT As String
  
  If Message <> "" Then TXT = Message & vbCrLf & vbCrLf
  TXT = TXT & "Error number: " & FormatErrorNumber(ErrX.Number) & vbCrLf & _
              "Description:  " & ErrX.Description
  
  MyMsgBox TXT, vbCritical
End Sub

Private Function FormatErrorNumber(ByVal Number As Long) As String
  Dim HexNum As String
  
  HexNum = UCase(Hex(Number))
  HexNum = String(8 - Len(HexNum), "0") & HexNum
  
  FormatErrorNumber = CStr(Number) & " (0x" & HexNum & ")"
End Function

'====================================================================
Private Function MyMsgBox(ByVal Prompt As String, _
                          Optional ByVal Buttons As VbMsgBoxStyle = vbOKOnly, _
                          Optional ByVal Title As String) As VbMsgBoxResult
  If Title = "" Then Title = Application.Name
  
  MyMsgBox = MsgBox(Prompt, Buttons, Title)
End Function
