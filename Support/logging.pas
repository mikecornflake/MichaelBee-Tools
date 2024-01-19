Unit Logging;

{$mode ObjFPC}{$H+}

Interface

Uses
  Classes, SysUtils;

Type
  TLogCallback = Procedure(Const AMessage: String) Of Object;

  { TLog }

  TLog = Class
  Private
    FLogFile: TextFile;
    FLogFileName: String;
    FIndentLevel: Integer;
    FLogCallback: TLogCallback;
    Function GetIndentString: String;
    Procedure SetLogCallback(AValue: TLogCallback);
  Public
    Constructor Create(Const ALogFileName: String);
    Destructor Destroy; Override;

    Procedure IncIndent;
    Procedure DecIndent;
    Procedure Log(Const AMessage: String);

    Function Filename: String;

    Property OnLog: TLogCallback read FLogCallback write SetLogCallback;
  End;

Procedure Debug(AMessage: String);
Procedure Debug(AMessage: TStringList);
Procedure Log_IncIndent;
Procedure Log_DecIndent;

Implementation

Var
  FLog: Tlog;

// Simple helper to simplify calling code
Procedure Debug(AMessage: String);
Begin
  If Assigned(FLog) Then
    FLog.Log(AMessage);
End;

Procedure Debug(AMessage: TStringList);
Var
  s: String;
Begin
  If Assigned(FLog) Then
    For s In AMessage Do
      Debug(s);
End;

Procedure Log_IncIndent;
Begin
  If Assigned(FLog) Then
    FLog.IncIndent;
End;

Procedure Log_DecIndent;
Begin
  If Assigned(FLog) Then
    FLog.DecIndent;
End;

{ TLog }

Constructor TLog.Create(Const ALogFileName: String);
Begin
  FLogFileName := ALogFileName;
  FIndentLevel := 0;

  FLog := Self;
End;

Destructor TLog.Destroy;
Begin
  Inherited Destroy;
End;

Function TLog.GetIndentString: String;
Begin
  Result := StringOfChar(' ', FIndentLevel * 2);
End;

Procedure TLog.SetLogCallback(AValue: TLogCallback);
Begin
  If FLogCallback = AValue Then Exit;
  FLogCallback := AValue;
End;

Procedure TLog.IncIndent;
Begin
  Inc(FIndentLevel);
End;

Procedure TLog.DecIndent;
Begin
  If FIndentLevel > 0 Then
    Dec(FIndentLevel);
End;

Procedure TLog.Log(Const AMessage: String);
Var
  sMessage: String;
Begin
  sMessage := Format('%s: %s%s', [FormatDateTime('yyyy-mm-dd hh:nn:ss', Now),
    GetIndentString, AMessage]);

    // Send to the main app if it wants
  If assigned(FLogCallback) Then
    FLogCallback(sMessage);

  // Output to file
  AssignFile(FLogFile, FLogFileName);
  Try
    // Create or overwrite the file
    If FileExists(FLogFileName) Then
      Append(FLogFile)
    Else
      Rewrite(FLogFile);

    Writeln(FLogFile, sMessage);
  Finally
    CloseFile(FLogFile);
  End;
End;

Function TLog.Filename: String;
Begin
  Result := FLogFileName;
End;

Initialization
  FLog := nil;

End.
