program TesseractConsole;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.Classes, System.SysUtils, System.Math, Vcl.Graphics;

type
  PTessBaseAPI = Pointer;
  PETEXT_DESC = Pointer;

function TessBaseAPICreate: PTessBaseAPI; cdecl; external 'libtesseract-3.dll';
function TessBaseAPIInit3(handle: PTessBaseAPI; datapath: PAnsiChar; language: PAnsiChar): Integer; cdecl; external 'libtesseract-3.dll';
procedure TessBaseAPISetImage(handle: PTessBaseAPI; imagedata: Pointer; width, height: Integer; bytes_per_pixel, bytes_per_line: Integer); cdecl; external 'libtesseract-3.dll';
function TessBaseAPIRecognize(handle: PTessBaseAPI; monitor: PETEXT_DESC): Integer; cdecl; external 'libtesseract-3.dll';
function TessBaseAPIGetUTF8Text(handle: PTessBaseAPI): PAnsiChar; cdecl; external 'libtesseract-3.dll';
procedure TessDeleteText(text: PAnsiChar); cdecl; external 'libtesseract-3.dll';
procedure TessBaseAPIEnd(handle: PTessBaseAPI); cdecl; external 'libtesseract-3.dll';
procedure TessBaseAPIDelete(handle: PTessBaseAPI); cdecl; external 'libtesseract-3.dll';

var
  hTesseract: PTessBaseAPI;
  bmp: TBitmap;
  pixels: PByteArray;
  msBitmap: TMemoryStream;
  y: Integer;
  exceptionMask: TFPUExceptionMask;
  pText: PAnsiChar;
  currentPath: String;
begin
  currentPath := ExtractFilePath(ParamStr(0));

  try
    hTesseract := TessBaseAPICreate();
    if TessBaseAPIInit3(hTesseract, PAnsiChar(AnsiString(currentPath + 'tessdata')), 'eng') <> 0 then
      raise Exception.Create('Unable to initalize Tesseract engine. Missing files?');

    bmp := TBitmap.Create;
    msBitmap := TMemoryStream.Create;
    try
      bmp.LoadFromFile(currentPath + 'text.bmp');
      for y := 0 to bmp.Height-1 do
      begin
        pixels := bmp.ScanLine[y];
        msBitmap.Write(pixels^, bmp.Width);
      end;
      TessBaseAPISetImage(hTesseract, msBitmap.Memory, bmp.width, bmp.height, 1, bmp.width);

      exceptionMask := GetExceptionMask;
      SetExceptionMask(exceptionMask + [exZeroDivide, exInvalidOp]);
      try
        if TessBaseAPIRecognize(hTesseract, nil) = 0 then
        begin
          pText := TessBaseAPIGetUTF8Text(hTesseract);
          if pText <> nil then
          begin
            WriteLn(pText);
            TessDeleteText(pText);
          end;
        end;
      finally
        SetExceptionMask(exceptionMask);
      end;
    finally
      bmp.Free;
      msBitmap.Free;
    end;

    TessBaseAPIEnd(hTesseract);
    TessBaseAPIDelete(hTesseract);
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;

  ReadLn;
end.
