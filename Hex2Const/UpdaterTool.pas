unit UpdaterTool;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Menus, StdCtrls, ComCtrls;

type
  TForm1 = class(TForm)
    Memo1: TMemo;
    OpenDialog1: TOpenDialog;
    StatusBar1: TStatusBar;
    Button1: TButton;
    Button2: TButton;

    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  bufferLen:integer;
  HexBuffer: array [0..8192] of byte;
implementation

{$R *.DFM}

Function HextoInt(hex:char):integer;
Begin
Case hex of
'0':HextoInt:=0;
'1':HextoInt:=1;
'2':HextoInt:=2;
'3':HextoInt:=3;
'4':HextoInt:=4;
'5':HextoInt:=5;
'6':HextoInt:=6;
'7':HextoInt:=7;
'8':HextoInt:=8;
'9':HextoInt:=9;
'A':HextoInt:=10;
'B':HextoInt:=11;
'C':HextoInt:=12;
'D':HextoInt:=13;
'E':HextoInt:=14;
'F':HextoInt:=15;
end;{case}
End;{hextoint}
{===================}
procedure TForm1.Button1Click(Sender: TObject);
var
  F1:textfile;
  FileBuffer: array [0..60000] of char;
  FileLength:integer;
   i,temp,linecount,chksum:integer;
  bytecount:byte;
  fileend:boolean;
  lineread:string;
Begin
 for i:=0 to 8191 do hexbuffer[i]:=255;
 If opendialog1.Execute=true then
 Begin
 {open firmware file and read to buffer}
 assignfile(f1,opendialog1.FileName);
 Reset(F1);
 i:=0;
       while not eof(f1) do {read file}
       begin
       Read(F1,Filebuffer[i]);
       inc(i);
       end;
       fileLength:=i;
       CloseFile(F1);

  End;{opendialog}
  statusbar1.Panels[0].text:='Loading file :'+opendialog1.filename;
  button2.enabled:=true;

i:=0;bufferlen:=0;fileend:=false;linecount:=0;
While not fileend Do
Begin
  If FileBuffer[i] = ':' then
  Begin
  Bytecount:=HextoInt(FileBuffer[i+1])*16+HextoInt(FileBuffer[i+2]);
    {check end of file}
    If FileBuffer[i+8]= '0' then
    Begin {chksum = LG+AA1+AA2+FF}
    chksum:=bytecount+hextoint(FileBuffer[i+3])*16+HextoInt(FileBuffer[i+4])+
    hextoint(FileBuffer[i+5])*16+HextoInt(FileBuffer[i+6])+
    hextoint(FileBuffer[i+7])*16+HextoInt(FileBuffer[i+8]);
    i:=i+9;lineread:='';
        For temp:=1 to bytecount Do {loop for load data to buffer}
        Begin
        HexBuffer[bufferlen]:=hextoint(FileBuffer[i])*16+HextoInt(FileBuffer[i+1]);
        lineread:=lineread+inttohex(HexBuffer[bufferlen],2);
        i:=i+2;
        chksum:=chksum+hexbuffer[bufferlen];
        inc(bufferlen);
        end;{for}
        chksum:= ((not chksum) and $FF)+1; {cal checksum each line}
        If chksum=$100 then chksum:=0; {if checksum>FF then 0}
        memo1.Lines.Add('$'+inttohex(linecount*16,4)+' : '+lineread+' , '+inttohex(chksum,2));
        inc(linecount);
      {check for checksum from loading file}
        If chksum<>(hextoint(FileBuffer[i])*16+HextoInt(FileBuffer[i+1])) then
        begin
        messagedlg('Firmware ต้นฉบับผิดพลาด! ไม่สามารถดำเนินการต่อได้'+#10+#13+'กรุณา Download โปรแกรมใหม่',MTerror,[MBOK],0);
        exit;
        end;
   end{If FileBuffer[i+8]= '0'}
  Else fileend:=true;
  End;{If FileBuffer[i]= ':'}
inc(i);
statusbar1.Panels[0].text:='BUFFER: '+inttostr(bufferlen)+' Byte Read';
end;{while}
{add credit}
memo1.lines.append('=============================================');
memo1.lines.append('Copy code below and paste in Firmware Updater');
memo1.lines.append('=============================================');
end;{hexread}
{=====================}

procedure TForm1.Button2Click(Sender: TObject);
var lineread:string;
     row:byte;
     i,j:integer;
begin
row:=0;i:=0;
While i<bufferlen Do
begin
   lineread:= 'Firmware'+inttostr(row)+' = '+chr(39);
   for j:=1 to 64 do
   Begin
   lineread:=lineread+inttohex(hexbuffer[i],2);
   inc(i);
   end;
   lineread:=lineread+chr(39)+';';
   inc(row);
   memo1.lines.add(lineread);
   lineread:='';
End;


end;

end.

