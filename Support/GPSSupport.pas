Unit GPSSupport;

{$mode objfpc}{$H+}

Interface

Uses
  Classes, SysUtils, WGS84;

// If you want to convert from EN to LATLON, then
// one of these HAS to be called first
Procedure InitialiseGPS(ALat, ALon: Double); Overload;
Procedure InitialiseGPS(AFuseau: Integer; ASouthernHemisphere: Boolean); Overload;

Function GetWGS88: TWGS84;
Procedure LatLonToEN(ALat, ALon: Double; Var AEast, ANorth: Double);
Procedure ENToLatLon(AEast, ANorth: Double; Var ALat, ALon: Double);

Function DummyGPGGA(ALat, ALon: Double; AAlt: Double = 0): String;
Function DummyGPGLL(ALat, ALon: Double): String;
Function DummyGPRMC(ALat, ALon: Double): String;
Function DummyGPGGAbyEN(AEast, ANorth: Double; AAlt: Double = 0): String;
Function DummyGPGLLbyEN(AEast, ANorth: Double): String;
Function DummyGPRMCbyEN(AEast, ANorth: Double): String;

Function LatAsDDMM(ALat: Double): String;
Function LonAsDDDMM(ALon: Double): String;

// Fuseau is the UTM Zone.  A number between 1 and 60
// Suspect this is the Swedish term for "UTM Zone"
// For consistency I'm sticking to the original
// nomenclature used in unit WGS84.
Function Fuseau: Integer;
Function SouthernHemisphere: Boolean;
Function Hemisphere: String;

Implementation

Uses
  StringSupport, Math;

Var
  FWGS84: TWGS84;
  FFuseau: Integer;
  FSouthernHemi: Boolean;

Function GetWGS88: TWGS84;
Begin
  If Not Assigned(FWGS84) Then
  Begin
    FWGS84 := TWGS84.Create;
    FWGS84.IgnoreGeodeticOrientation := True;
  End;

  Result := FWGS84;
End;

Procedure InitialiseGPS(ALat, ALon: Double);
Begin
  FFuseau := floor((ALon + 180) / 6) + 1;
  FSouthernHemi := (ALat < 0);
End;

Procedure InitialiseGPS(AFuseau: Integer; ASouthernHemisphere: Boolean);
Begin
  FFuseau := AFuseau;
  FSouthernHemi := ASouthernHemisphere;
End;

Procedure LatLonToEN(ALat, ALon: Double; Var AEast, ANorth: Double);
Var
  oLatLon: TrecLatLon;
  oUTM: TrecUTM;
  oWGS84: TWGS84;
Begin
  oLatLon.Lat := ALat;
  oLatLon.Lon := ALon;

  oWGS84 := GetWGS88;
  oWGS84.WGS84ToUTM(oLatLon, oUTM{%H-});

  FFuseau := oUTM.fuseau;
  FSouthernHemi := oUTM.southhemi;

  AEast := oUTM.X;
  ANorth := oUTM.Y;
End;

Procedure ENToLatLon(AEast, ANorth: Double; Var ALat, ALon: Double);
Var
  oLatLon: TrecLatLon;
  oUTM: TrecUTM;
  oWGS84: TWGS84;
Begin
  If FFuseau = -1 Then
    Raise Exception.Create('Fuseau (UTM Zone) not defined.  Call InitialiseGPS first.');

  oUTM.X := AEast;
  oUTM.Y := ANorth;

  oUTM.southhemi := FSouthernHemi;
  oUTM.fuseau := FFuseau;

  oWGS84 := GetWGS88;
  oWGS84.UTMToWGS84(oUTM, oLatLon{%H-});

  ALat := oLatLon.Lat;
  ALon := oLatLon.Lon;
End;

Function Checksum(AInput: String): Byte;    // calcul Checksum
Var
  x: Integer;
  cCheckCalc: Byte;
Begin
  x := 1;
  cCheckCalc := 0;
  While AInput[x] <> '*' Do
  Begin
    If AInput[x] <> '$' Then  cCheckCalc := Ord(AInput[x]) Xor cCheckCalc;
    x := x + 1;
  End;
  Checksum := cCheckCalc;
End;

// https://docs.novatel.com/OEM7/Content/Logs/GPGGA.htm
Function DummyGPGGA(ALat, ALon: Double; AAlt: Double): String;
Var
  sLat, sLon: String;
Begin
  If ALat > 0 Then
    sLat := 'N'
  Else
    sLat := 'S';

  If ALon > 0 Then
    sLon := 'E'
  Else
    sLon := 'W';

  Result := Format('$GPGGA,%s,%s,%s,%s,%s,8,1,1,%.3f,M,1,M,,*',
    [FormatDateTime('hhnnss".00"', now), LatAsDDMM(ALat), sLat, LonAsDDDMM(ALon), sLon, AAlt]);
  Result := Result + IntToHex(Checksum(Result), 2);

  //Str := '$GPGGA,' +
  //       FormatDateTime('hhnnss".00,"',now ) +
  //       ChaineLatitude +
  //       ',' + PoleLat + ',' +
  //       ChaineLongitude +
  //       ',' + PoleLon + ',' +
  //       '1,04,47.56,' + EditAlt.Text + ',M,10,M,,*';
  //Str := Str + inttohex(checksum(Str),2)+ Char(13)+ Char(10);
End;

// https://docs.novatel.com/OEM7/Content/Logs/GPGLL.htm
Function DummyGPGLL(ALat, ALon: Double): String;
Var
  sLat, sLon: String;
Begin
  If ALat > 0 Then
    sLat := 'N'
  Else
    sLat := 'S';

  If ALon > 0 Then
    sLon := 'E'
  Else
    sLon := 'W';

  Result := Format('$GPGLL,%s,%s,%s,%s,%s,A,M*', [LatAsDDMM(ALat), sLat,
    LonAsDDDMM(ALon), sLon, FormatDateTime('hhnnss".00"', now)]);
  Result := Result + IntToHex(Checksum(Result), 2);

  //Str := '$GPGLL,' +
  //     ChaineLatitude +
  //     ',' + PoleLat + ',' +
  //     ChaineLongitude +
  //     ',' + PoleLon + ',' +
  //     FormatDateTime('hhnnss".00,"',now ) +
  //     'A*';
End;

// https://docs.novatel.com/OEM7/Content/Logs/GPRMC.htm
Function DummyGPRMC(ALat, ALon: Double): String;
Var
  sLat, sLon: String;
Begin
  If ALat > 0 Then
    sLat := 'N'
  Else
    sLat := 'S';

  If ALon > 0 Then
    sLon := 'E'
  Else
    sLon := 'W';

  Result := Format('$GPRMC,%s,A,%s,%s,%s,%s,,,%s,,E*',
    [FormatDateTime('hhnnss', now), LatAsDDMM(ALat), sLat, LonAsDDDMM(ALon),
    sLon, FormatDateTime('ddmmyy', now)]);
  Result := Result + IntToHex(Checksum(Result), 2);
  //Str := '$GPRMC,' +
  //       FormatDateTime('hhnnss","',now ) +
  //       'A,' +
  //       ChaineLatitude +
  //       ',' + PoleLat + ',' +
  //       ChaineLongitude +
  //       ',' + PoleLon + ',' +
  //       '000.5,054.7,' +
  //       FormatDateTime('ddmmyy","',now ) +
  //       '020.3,E*';
End;

Function DummyGPGGAbyEN(AEast, ANorth: Double; AAlt: Double): String;
Var
  dLat: Double = 0;
  dLon: Double = 0;
Begin
  ENToLatLon(AEast, ANorth, dLat, dLon);
  Result := DummyGPGGA(dLat, dLon, AAlt);
End;

Function DummyGPGLLbyEN(AEast, ANorth: Double): String;
Var
  dLat: Double = 0;
  dLon: Double = 0;
Begin
  ENToLatLon(AEast, ANorth, dLat, dLon);
  Result := DummyGPGLL(dLat, dLon);
End;

Function DummyGPRMCbyEN(AEast, ANorth: Double): String;
Var
  dLat: Double = 0;
  dLon: Double = 0;
Begin
  ENToLatLon(AEast, ANorth, dLat, dLon);
  Result := DummyGPRMC(dLat, dLon);
End;

Function LatAsDDMM(ALat: Double): String;
Begin
  Result := FormatFloat('0000.0000000', Trunc(Abs(ALat)) * 100 +
    (Abs(ALat) - Trunc(Abs(ALat))) * 60);
End;

Function LonAsDDDMM(ALon: Double): String;
Begin
  Result := FormatFloat('00000.0000000', Trunc(Abs(ALon)) * 100 +
    (Abs(ALon) - Trunc(Abs(ALon))) * 60);
End;

Function Fuseau: Integer;
Begin
  Result := FFuseau;
End;

Function SouthernHemisphere: Boolean;
Begin
  Result := FSouthernHemi;
End;

Function Hemisphere: String;
Begin
  If FSouthernHemi Then
    Result := 'Southern hemisphere'
  Else
    Result := 'Northern hemisphere';
End;

Initialization
  FWGS84 := nil;
  FFuseau := -1;
  FSouthernHemi := True;

Finalization
  FreeAndNil(FWGS84);

End.
