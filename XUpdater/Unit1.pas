unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, inpout32,ExtCtrls, Buttons, ComCtrls, Grids,  MPlayer,Math;

type
  Tlogofile = Record
   buf:byte
   end;

  TForm1 = class(TForm)
    WriteTimer: TTimer;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    StatusBar1: TStatusBar;
    Shape1: TShape;
    BitBtn3: TBitBtn;
    Panel1: TPanel;
    Memo1: TMemo;
    Bevel1: TBevel;
    Bevel2: TBevel;
    Image1: TImage;
    Label2: TLabel;
    Image3: TImage;
    TrackBar1: TTrackBar;
    Label1: TLabel;
    Label3: TLabel;
    Panel3: TPanel;
    StringGrid1: TStringGrid;
    BitBtn4: TBitBtn;
    UpDown1: TUpDown;
    BitBtn6: TBitBtn;
    Memo2: TMemo;
    Panel2: TPanel;
    Image2: TImage;
    Edit1: TEdit;
    BitBtn5: TBitBtn;
    CheckBox1: TCheckBox;
    setuptimer: TTimer;
    m3timer: TTimer;
    Bevel3: TBevel;
    Gauge1: TProgressBar;
    DrawGrid1: TDrawGrid;
    DrawGrid2: TDrawGrid;
    DrawGrid3: TDrawGrid;
    DrawGrid4: TDrawGrid;
    DrawGrid5: TDrawGrid;
    DrawGrid6: TDrawGrid;
    LoadDefaultLogoBTN: TBitBtn;
    Memo3: TMemo;
    clearlogobtn: TBitBtn;
    Label4: TLabel;
    Memo4: TMemo;
    BlinkTimer: TTimer;
    Button1: TButton;
    Button2: TButton;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;


    procedure BitBtn2Click(Sender: TObject);
    procedure Shape1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn5Click(Sender: TObject);
    procedure CheckBox1Click(Sender: TObject);
    procedure WriteTimerTimer(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure setuptimerTimer(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure StatusBar1DblClick(Sender: TObject);

    procedure TrackBar1Change(Sender: TObject);
    procedure BitBtn3Click(Sender: TObject);
    procedure UpDown1Click(Sender: TObject; Button: TUDBtnType);
    procedure StringGrid1SelectCell(Sender: TObject; Col, Row: Integer;
      var CanSelect: Boolean);
    procedure BitBtn4Click(Sender: TObject);
    procedure BitBtn6Click(Sender: TObject);
    procedure m3timerTimer(Sender: TObject);
    procedure DrawGrid1Click(Sender: TObject);
    procedure LoadDefaultLogoBTNClick(Sender: TObject);
    procedure DrawGrid2Click(Sender: TObject);
    procedure DrawGrid2DblClick(Sender: TObject);
    procedure DrawGrid1DblClick(Sender: TObject);
    procedure DrawGrid3Click(Sender: TObject);
    procedure DrawGrid4Click(Sender: TObject);
    procedure DrawGrid5Click(Sender: TObject);
    procedure DrawGrid6Click(Sender: TObject);
    procedure DrawGrid3DblClick(Sender: TObject);
    procedure DrawGrid4DblClick(Sender: TObject);
    procedure DrawGrid5DblClick(Sender: TObject);
    procedure DrawGrid6DblClick(Sender: TObject);
    procedure clearlogobtnClick(Sender: TObject);
    procedure BlinkTimerTimer(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);


  private
    { Private declarations }
  public
    { Public declarations }

  end;

var
  Form1: TForm1;
  HexBuffer: array [0..8191] of byte;
  EEPROM: array [0..127] of byte;
  LogoEdit: array [0..47] of byte;
  SpeedControl:integer;
  bypass,timertrig,firststart:boolean;
  debugcount:byte; {counter to show hidden debug window}

  Dumpfile: File of TLogofile;

Const
  EnableCmd      = '10101100010100110000000000000000';
  EraseCmd       = '10101100100000000000000000000000';
  LockBit1       = '10101100111000000000000000000000';
  LockBit2       = '10101100111000010000000000000000';
  LockBit3       = '10101100111000100000000000000000';
  LockBit4       = '10101100111000110000000000000000';
  ReadLockBit    = '001001000000000000000000';
  PageWrite      = '0101000';
  PageRead       = '0011000';
  UserMsgIndex   = $13DB;   {79*64 + 27 index to replace data in HexBuffer}
  {Keyword to search User Message Index is D2D2D2D2D2D2D2D2D2 (" ----------------")}
  UserLogoIndex  = $161A;   {88*64 + 26 index to replace data in HexBuffer}
  {Keyword to search logo index is 00000106080C1B100D0 (CGUL)}
  {Default PID limit value}
  EEPROM0        = '1F0544FFE5898E8EFFFFFA6566A0FF82';{00-15}
  EEPROM1        = '14CCFFFF2A2AFFFFFFFFFFFFFFFFFFFF';{16-31}
  EEPROM2        = 'FFFF06FFFFFFFFFFFFFFFFFFFFFFFF0C';{32-47}
  EEPROM3        = 'FFFFFF66FFFFFFFFFFFFFFFF1B1BFFFF';{48-63}
  EEPROM4        = 'FFFF2BE5FFE550FFFFFFFFFFFFFFFFFF';{64-79}

MazdaLogo = '00000106080C1B100D0000001F000000110A0D000000100C02061B010D001010080E030000000D0004040000111F00000D000101020E180000000D00';

Firmware0 = '787F760018B800FA75F000758180758780758922758DFD759852D28EC2AC750804750911750A01751006751579751824C2A0D2B0C2A37440120FA290161A120F';
Firmware1 = '4A901624120F4A90162E120F4A901638120F4A901642120F4A90164C120F4A901606120F4A901610120F4A7401120FA21210EB7438120FA2740C120FA2741012';
Firmware2 = '0FA27407120FA27480120FA29013C2120F7874C0120FA29013D7120F787406120FA220B26912111C7401120FA21210EB7480120FA2901585120F4A74C0120FA2';
Firmware3 = '9015C7120F4A740D120FA2C296C29720B3031211423097F774C0120FA29015DC120F4A780174007F083097FDA29533D2962097FDC296DFF1F912124808B880E5';
Firmware4 = '74C0120FA290159B120F4A12111C20B44320B54012111C7401120FA21210EB7480120FA29015B1120F4A74C0120FA29015C7120F4A740D120FA2C296C29720B3';
Firmware5 = '031211423097F774C0120FA29015DC120F4A80FE1210DA1210DA1210DA1210DA1210DA1210DAC2B6C2B77401120FA21210EB12112D7480120FA29013EC120F4A';
Firmware6 = '740D120FA290139A1210AD1210EB9013A01210AD1210EB9013A61210AD1210EB9013AC1210AD1210EB9013B41210AD1210EBC29874C0120FA29018C1120F4A74';
Firmware7 = 'C0120FA29013941210AD743E120FB11210CDB43403020200B40DF174C1120FA20201E6120FB11210CDB40DF71210DA1210DA1210DA1210DA1210DA1210DA80B2';
Firmware8 = '1210CDB43EFA740C120FA278001212942014268910E51085E0197801121294890878021212948909A8081212948916A809121294891702025FE510C2E4F51074';
Firmware9 = 'C0120FA2901919120F4A12111C1210DA1210DA1210DA1210DA1210DA1210DA120D32120E3E740D1210C5E51930E00920A704C2A38002D2A320B308121142740D';
Firmware10 = '1210C530B25520985420B42612112D0508E508120953F508A8081212948916120D321210EB1210EB1210EB740D1210C580B820B5B512112D0509E509120953F5';
Firmware11 = '09A8091212948917120E3E1210EB1210EB1210EB740D1210C5808F618B1210B8E50AB40152120FC0AA0812098312114F7480250B120FA2A90F7820E6120FB108';
Firmware12 = 'D9F9750A02E509B42205121087418974301210C574311210C5E509C4540FF912109D1210C5E509540FF912109D1210C5740D1210C54189120FC0AA0912098312';
Firmware13 = '118B74C0250C120FA2A90F7820E6120FB108D9F9750A01E508B42205121087418974301210C574311210C5E508C4540FF912109D1210C5E508540FF912109D12';
Firmware14 = '10C5740D1210C54189E1FDC2B6C2B712111C7C0A7D647F037E9820B2ECDEFBDFF7DDF3DCEF7480120FA2901403120F4A74C0120FA29014C7120F4A20B3031211';
Firmware15 = '4220B502C14220B4F212112D7401120FA21210EB7480120FA2901419120F4A74C0120FA290156F120F4A74C0120FA2E51030E014744F120FB1744E120FB17420';
Firmware16 = '120FB1C2A3020419744F120FB17446120FB17446120FB1D2A31210DA20B30312114230B41020B5F412112DE510B2E0F510F51980B512112D7401120FA21210EB';
Firmware17 = '7480120FA290142F120F4A74C0120FA290156F120F4A74C0120FA2E51030E112744F120FB1744E120FB17420120FB1020481744F120FB17446120FB17446120F';
Firmware18 = 'B11210DA20B30312114230B40E20B5F412112DE510B2E1F51080BB12112D7401120FA21210EB74C0120FA2901444120F4A120D321210DA20B30312114230B411';
Firmware19 = '20B5F412112D0508E508120953F50880E07801A90812124812112D7401120FA21210EB7480120FA290145A120F4A120E3E1210DA20B30312114230B41120B5F4';
Firmware20 = '12112D0509E509120953F50980E07802A90912124812112D7401120FA21210EB7480120FA2901470120F4A74C0120FA290156F120F4A74C0120FA2E51030E312';
Firmware21 = '744F120FB1744E120FB17420120FB1020561744F120FB17446120FB17446120FB11210DA20B30312114230B40E20B5F412112DE510B2E3F51080BB12112D7401';
Firmware22 = '120FA21210EB7480120FA2901486120F4A74C0120FA290156F120F4A74C0120FA2E51030E412744F120FB1744E120FB17420120FB10205C7744F120FB1744612';
Firmware23 = '0FB17446120FB11210DA20B30312114230B40E20B5F412112DE510B2E4F51080BB12112D7401120FA21210EB7480120FA290149B120F4A74C0120FA29014B112';
Firmware24 = '0F4A1210DA20B30312114220B4F712112D1210DAA9107800121248201402415F74C0120FA290192F120F4A12111C1210DA1210DA1210DA1210DA1210DA1210DA';
Firmware25 = '415F12112D7401120FA21210EB7480120FA29014DD120F4A1210DA20B30312114220B4F712112D7401120FA21210EB7480120FA29014F3120F4AC29890154B12';
Firmware26 = '10AD1210B8120FC0E50D60049480F50D900000850D821210FC7491120FA2EBC4540F2430120FB1EB540F2430120FB174C0120FA2E50D701A901509120F4A1210';
Firmware27 = 'DA20B30312114220B4F712112D1210DA415FD2B690151F120F4A12111C1210DA20B30312114220B5F712112D74C0120FA2901555120F4A9015511210AD1210B8';
Firmware28 = 'F6781908B634FC08B633F8E82404F875130074C0120FA208B63E0302079A08B63E0302079A18B6200280ECB60D0280E7B63A0280E208B63A0280DC18B6300808';
Firmware29 = 'B6300302079A18881190000005138513821210FCEB54F0C412109D120FB1EB540F12109D120FB1742D120FB1A811121314E9120FB1EA120FB108E6120FB10808';
Firmware30 = 'E6120FB108E6120FB11210DA20B30312114220B5F712112DE11274C0120FA2901535120F4A75130074CF120FA2E51330E0127459120FB17445120FB17453120F';
Firmware31 = 'B10207D3744E120FB1744F120FB17420120FB11210DA20B30312114230B40E20B5F412112DE513B2E0F51380BBE51330E00690156B1210AD1210DA415F740112';
Firmware32 = '0FA21210EB7480120FA29018D7120F4A74C0120FA2E51020E2099018ED120F4A020829901903120F4A9015F21210AD1210B8120FC0850D11120AB87480120FA2';
Firmware33 = 'A90F7820E6120FB108D9F99015F81210AD1210B8120FC0850D12850E13120BA6748B120FA2A90F7820E6120FB108D9F9A912A8137B007A0A1211C78912881379';
Firmware34 = '00A8117B017A131211FDAB12AA131211C789838882E51030E24F0515A815A68308A6828815E515B4FF6C78807981868387827882E6FB08E6FAA983A882751183';
Firmware35 = '12123C898388820511A811E6FB08E6FA8811A983A882E511B4FFE57B007A401211C78983888275157F1210FC74CC120FA2EA540F600524300208FD7417120FB1';
Firmware36 = 'EBC4540F2430120FB1742E120FB1EB540F2430120FB120B30312114220B40C12112DE510C2E2F5100207FD20B50C12112DE510D2E2F5100207FD20B21312112D';
Firmware37 = '7800A9101212481210DA1210DA02025F020829B40803740A22B41203741422B41603742222B42403742C22B43003743322B43403743C22B43E03744222B44702';
Firmware38 = '740422BA0404120A4722BA0504120A8922BA0604120AF022BA0704120AF022BA0A04120AB822BA0B04120AB822BA0C04120B2E22BA0D04120AB822BA0E04120B';
Firmware39 = '7022BA0F04120A8922BA1004120BA622BA1104120A4722BA1404120C9B22BA1504120C9B22BA2204120CCF22BA2304120BA622BA2C04120A4722BA2D04120A47';
Firmware40 = '22BA2E04120A4722BA2F04120A4722BA3304120AB822BA3C04120BE722BA3D04120BE722BA4204120C3522BA4304120A4722BA4404120C6922BA4504120A4722';
Firmware41 = 'BA4603120A8922E50D75F064A4900000F5821210FCEA90000085F08225F0900000F5821210FCEA540FFC60072430F520020A76752017EBC4540F2430F521EB54';
Firmware42 = '0F2430F522750F0322900000E50DC39428F5821210FCEA540F60072430F520020AA5752017EBC4540F2430F521EB540F2430F522750F0322900000850D821210';
Firmware43 = 'FCEA540F60072430F520020AD0752017EBC4540FAF20BF170260072430F521020AE5752117EB540F2430F522750F0322E50D75F064A4A9F0F87B007A801211C7';
Firmware44 = 'C3E89464400775202B020B1375202DFC74649C900000F5821210FCEBC4540F2430F521EB540F2430F522750F0322E50D75F00484F5837440A4FCE50E75F00484';
Firmware45 = '2CF5821210FCEAC4540F60072430F520020B56752017EA540F2430F521EBC4540F2430F522EB540F2430F523750F0422E50D75F00284C39440400775202B020B';
Firmware46 = '8A75202DFC74FF9C2402900000F582FC1210FCEBC4540F2430F521EB540F2430F522750F0322850D83850E821210FCE960072430F520020BBC752017EAC4540F';
Firmware47 = 'AF20BF170260072430F521020BD1752117EA540F2430F522EBC4540F2430F52475232E750F0522850D83850E821210FCEA75F01084AAF075F00AA42A940475F0';
Firmware48 = '0A84AAF075F010A42AC4540F60072430F520020C18752017EA540F2430F521EBC4540F2430F522EB540F2430F52475232E750F0522850D83850E821210FCE960';
Firmware49 = '072430F520020C4B752017EAC4540F2430F521EA540F2430F523EBC4540F2430F52475222E750F0522E50D75F064A4A9F0F87B007A801211C7898388821210FC';
Firmware50 = 'EA2430F52075212EEBC4540F2430F522EB540F2430F523750F0422E50D75F064A4A9F0F87B007AC81211C7898388821210FCEA540F2430F52075212EEBC4540F';
Firmware51 = '2430F522EB540F2430F523750F0422E50D9401F9A80E7B007A641211FD8A0D7B007A901211C789118812E50DC4F978007B007A091211C7AB11AA1212123C8983';
Firmware52 = '88821210FCEAC4540F60072430F520020D15752017EA540F2430F521EBC4540F2430F522EB540F2430F52475232E750F05227480120FA2E508B4040690165602';
Firmware53 = '0E38B4050690166C020E38B40606901682020E38B40706901698020E38B40A069016AE020E38B40B069016C4020E38B40C069016DA020E38B40D069016F0020E';
Firmware54 = '38B40E06901706020E38B40F0690171C020E38B41006901732020E38B41106901748020E38B4140690175F020E38B41506901775020E38B422069018AB020E38';
Firmware55 = 'B4230690178B020E38B42C069017A1020E38B42D069017B7020E38B42E069017CD020E38B42F069017E3020E38B433069017F9020E38B43C0690180F020E38B4';
Firmware56 = '3D06901825020E38B4420690183B020E38B44306901851020E38B44406901867020E38B4450690187F020E38B44606901895020E389018C1120F4A890B2274C0';
Firmware57 = '120FA2E509B40406901656020F44B4050690166C020F44B40606901682020F44B40706901698020F44B40A069016AE020F44B40B069016C4020F44B40C069016';
Firmware58 = 'DA020F44B40D069016F0020F44B40E06901706020F44B40F0690171C020F44B41006901732020F44B41106901748020F44B4140690175F020F44B41506901775';
Firmware59 = '020F44B422069018AB020F44B4230690178B020F44B42C069017A1020F44B42D069017B7020F44B42E069017CD020F44B42F069017E3020F44B433069017F902';
Firmware60 = '0F44B43C0690180F020F44B43D06901825020F44B4420690183B020F44B44306901851020F44B44406901867020F44B4450690187F020F44B44606901895020F';
Firmware61 = '449018C1120F4A890C227820E493F6B40D03020F59A30880F308760DA3E493F97820E6B40D0122D2A200D2A100F58000C2A21210D50880EA7820E493F6B40D03';
Firmware62 = '020F87A30880F308760D7820E6B40D0122D2A200D2A100F58000C2A21210EB0880EAD2A200C2A100F58000C2A21210EB22D2A200D2A100F58000C2A21210D522';
Firmware63 = 'E520B434267518247826E612108EC4F50D08E612108E790DD77829E612108EC4F50E08E612108E790ED722B436267518247829E612108EC4F50D08E612108E79';
Firmware64 = '0DD7782CE612108EC4F50E08E612108E790ED722D51849E51030E44412111C7401120FA21210EB7480120FA2901945120F4A74C0120FA290195B120F4A1210DA';
Firmware65 = '12112D1210DA12112D1210DA12112D1210DA7408120FA2C2B6C2B7D2A3021067750D00750E00229013941210AD1210CDB434099013BC1210AD12130D75110A12';
Firmware66 = '10DAD511FA80E09015FE1210AD2275F04184B40104E6943722E6942F22FF75F00A84B40104EF243722EF243022E493700122A31210C580F578201210CDB43E01';
Firmware67 = '22F60880F53099FDC299F599223098FDC298E599227E1FDEFE227C0A7D647F037E98DEFEDFFADDF6DCF2227C027D327F037E98DEFEDFFADDF6DCF2227400F9FA';
Firmware68 = 'FB7C10E58233F582E58333F5837D037803E635E0D4F618DDF8DCE822C2A47B077CFF7DFFDDFEDCFADBF6D2A422E51020E10311EB22C2A47B307CFFDCFEDBFAD2';
Firmware69 = 'A42220A305D2A311DA22C2A311DA22E51030E32CE50D8516F084FFE508B40A03021183B41403021183B41503021183B42F03021183B44203021183EF6002D2B6';
Firmware70 = 'C2B722EF70FAD2B6C2B722E51030E32CE50D8517F084FFE509B40A030211BFB414030211BFB415030211BFB42F030211BFB442030211BFEF6002D2B7C2B622EF';
Firmware71 = '70FAD2B7C2B6227F007E0075F010C3E833F8E933F9EE33FEEF33FFEEC39AF582EF9BF583B35004AF83AE82EC33FCED33FDD5F0DAEDF9ECF8EFFBEEFA22C0F0C0';
Firmware72 = '82E88AF0A4C0E0C0F0E88BF0A4D00028F8E435F0F582EA89F0A428F8E58235F0F582E43400C0E0EB89F0A42582FAD0E035F0FBA900D000D082D0F02253D0E7E8';
Firmware73 = '2AF8E93BF9A2D222121307D2A5D2A6C2A5121307C2A6D2A574A012127720140DE8547F121277201404E9121277C2A5D2A6121307D2A522C2147A083392A51212';
Firmware74 = 'F71212FFDAF5D2A51212F730A502D2141212FF22D2A5D2A6C2A5121307C2A674A0517720142AE8547F5177201422C2A5D2A6121307D2A5D2A5D2A6C2A5121307';
Firmware75 = 'C2A674A151772014071212DA201401F9C2A5D2A6121307D2A522C2147A081212F7A2A5331212FFDAF5D2A51212F720A502D2141212FF22D2A6000000000022C2';
Firmware76 = 'A600000000002200000000002275A61E75A6E122B6300579507A3022B6310579507A3122B6320579507A3222B6330579507A3322B6340579437A3022B6350579';
Firmware77 = '437A3122B6360579437A3222B6370579437A3322B6380579427A3022B6390579427A3122B6410579427A3222B6420579427A3322B6430579557A3022B6440579';
Firmware78 = '557A3122B6450579557A3222B6460579557A3322303130300D00415445300D0041544C300D00415448300D004154535430300D004154535041360D0041545753';
Firmware79 = '0D00000102204F4244494920582D4D455445522056310D030405202D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D0D43726561746564206279205261747468616E696E';
Firmware80 = '060D0053656C656374205345545550204D656E755B7E5D0D00312E204175746F204261636B6C696768742020200D00322E2053657420535045414B4552202020';
Firmware81 = '20200D00332E205365742073746172742D757020504944310D00342E205365742073746172742D757020504944320D00352E20504944205761726E696E67204C';
Firmware82 = '696768740D00362E204175746F20536C656570204D6F64652E0D00372E204669726D776172652056657220312E30370D0046656232332C323031367C4A617661';
Firmware83 = '4A61636F620D005370656369616C2046756E6374696F6E205B7E5D0D00312E2056656820496E666F204E756D626572733A0D00322E204E6F2E206F6620445443';
Firmware84 = '73203D202D2D200D104D494C20737461747573206973204F46462E2E2E0D00507265737320746F2072656164204454435B7E5D0D00436C656172204D494C206E';
Firmware85 = '6F773F5B4E4F205D7E0D00303130310D0030330D002020202020202020206E657874204454435B7E5D0D0030340D002020202020507265737320746F20736574';
Firmware86 = '5B7E5D0D005B534554204C494D49545445442056414C55455D0D0053657474696E6720636F6D706C657465212E2E2E0D005B2055504752414445204649524D57';
Firmware87 = '415245205D0D0057616974696E6720636F6E6E656374696F6E2E0D004E6F7720557067726164696E672E2E2E202020200D00303130440D00303131300D003232';
Firmware88 = '314531430D0008140803040404030D0008140807050604040D0000000106080C1B100D0000001F000000110A0D000000100C02061B010D001010080E03000000';
Firmware89 = '0D0004040000111F00000D000101020E180000000D0043414C20456E67696E65204C6F6164202D2D2D250D10436F6F6C616E742054656D703A202D2D2D20DF63';
Firmware90 = '0D0E532D54204675656C205472696D31202D2D2D20250D0F4C2D54204675656C205472696D31202D2D2D20250D0F4675656C205072657373757265202D2D2D6B';
Firmware91 = '50610D0E4D414E20416972205072657373202D2D2D6B50610D0E454E472053706565643A202D2D2D2D2052504D200D0B5645482053706565643A202D2D2D206B';
Firmware92 = '6D2F68200D0B49474E204144562054696D696E673A202D2D2DDF0D10496E74616B65204169722054656D70202D2DDF630D0F41697220466C6F77202D2D2D2E2D';
Firmware93 = '20672F7365630D095468726F74746C6520506F733A202D2D2D202520200D0E46726F6E7420484F325320566F6C74202D2E2D2D0D10526561722020484F325320';
Firmware94 = '566F6C74202D2E2D2D0D105261696C205072657373202D2D2D2E2D204D50610D0B436F6D6D616E646564204547523A202D2D2D20250D0F454752204572726F72';
Firmware95 = '3A202D2D2D2025202020200D0B434D442045766170205075726765202D2D2D20250D0F4675656C204C6576656C3A202D2D2D20252020200D0C4261726F205072';
Firmware96 = '657373757265202D2D2D6B50610D0E43415420312054656D703A202D2D2D2E2D20DF630D0C43415420322054656D703A202D2D2D2E2D20DF630D0C50434D2056';
Firmware97 = '6F6C746167653A202D2D2E2D2D20560D0D41425320456E67696E65204C6F6164202D2D2D250D10434D442045515620526174696F3A202D2E2D2D2020200D0F52';
Firmware98 = '454C205468726F7420506F733A202D2D2D20250D0F414D42204169722054656D703A202D2D2D20DF630D0E5472616E7320466C756964202D2D2D2E2D20DF630D';
Firmware99 = '0C20202020202020202020202020202020202020200D002D2D2D206B6D2F687C4146202D2D2E2D20672F730D0043757272656E7420462F43202D2D2E2D6B6D2F';
Firmware100 = '4C0D004176657261676520462F43202D2D2E2D6B6D2F4C0D00454550524F4D2052656164696E67204572726F720D00454550524F4D2057726974696E67204572';
Firmware101 = '726F720D00456E67696E65206973207475726E6564206F66660D0053776974636820746F20534C454550206D6F64650D00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFF';

FWCount = 101; {0-100}
bufferlen = (FWCOUNT+1)*64;


implementation

{$R *.DFM}
{pin use
37A.0 STROBE   = SCK
37A.1 autofeed = RESET
37A.2 init     =  not use
37A.3 SLCT IN  = MOSI
379.6 ACK      = MISO    }
{========================================}
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
Procedure clrb(port:integer;bit:byte);
var data:byte;
Begin
data:= inp32(port);
Case bit of
0:out32(port,data or 1);
1:out32(port,data or 2);
2:out32(port,data or 4);
3:out32(port,data or 8);
4:out32(port,data or 16);
5:out32(port,data or 32);
6:out32(port,data or 64);
7:out32(port,data or 128);
end;
End;
{===============================}
Procedure setb(port:integer;bit:byte);
var data:byte;
Begin
data:=inp32(port);
Case bit of
0:out32(port,data and 254);
1:out32(port,data and 253);
2:out32(port,data and 251);
3:out32(port,data and 247);
4:out32(port,data and 239);
5:out32(port,data and 223);
6:out32(port,data and 191);
7:out32(port,data and 127);
end;{case}
End;
{============================}
Procedure Clock;
var c:integer;
Begin
for c:=0 to speedcontrol do begin end;
setb($37A,0);
for c:=0 to speedcontrol do begin end;
clrb($37A,0);
for c:=0 to speedcontrol do begin end;
End;
{==========================}
Procedure Chipenable;
var i:Integer;
Begin
   clrb($37A,1);{reset low}
   for i:=0 to 1500000*speedcontrol do begin end;
   clrb($37A,0);  {sck low}
   setb($37A,1); {RESET HIGH}
   for i:=0 to 1500000*speedcontrol do begin end;
for i:=1 to 32 Do  {enable chip}
Begin
CAse EnableCmd[i] of
     '0':clrb($37A,3);
     '1':setb($37A,3);
     end;{case}
     {clock after 1 bit}
Clock;
end;
for i:=0 to 150*speedcontrol do begin end;
End;
{===========================}
Procedure ChipErase;
Var i:byte;
Begin
for i:=1 to 32 Do  {erase chip}
Begin
Case EraseCmd[i] of
     '0':clrb($37A,3);
     '1':setb($37A,3);
     end;{case}
     {clock after 1 bit}
clock;
end;
End;
{===========================}
Procedure ChipReset;
var i:integer;
Begin
setb($37A,1);   {set RESET high}
for i:=0 to 1000000 do begin end;
clrb($37A,1); {delay timer then low RESET}
end;
{=============================}
Procedure EEPROMClock;
Begin
setb($37A,0);
while (inp32($379) and  64 = 0) do begin end;
{wait for 1 bit read OK signal MISO from X-METER}
clrb($37A,0);
End;
{==========================}
procedure TForm1.BitBtn2Click(Sender: TObject);
begin
form1.Close; {exit program}
end;
{========================}
procedure TForm1.Shape1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
inc(debugcount);
If (debugcount = 3) and (memo2.visible=false) then
begin
while form1.top<800 Do
begin
form1.Height:=form1.height-2;
form1.Width:=form1.width-2;
form1.left:=form1.left+1;
form1.top:=form1.top+1;
beep;
end;
halt;
end;
If (debugcount = 5)and (memo2.visible=true) then
begin panel1.Visible:=true;panel2.visible:=false;
      Panel3.visible:=false; memo2.visible:=false;
      debugcount:=0;
end;
end;
{==========================}
procedure TForm1.BitBtn5Click(Sender: TObject);
begin
edit1.Clear;
end;
{--------------}

{==================================}
procedure TForm1.BitBtn1Click(Sender: TObject);{start download}
var i:integer;
    Userstring:string[20];
begin
Panel1.Visible:=false;Panel2.Visible:=true;
Panel3.Visible:=false; memo2.visible:=false;
 setb($37A,0);  {sck low tell X-Meter connecting OK}
bitbtn1.enabled:=false;
trackbar1.Enabled:=false;
Gauge1.Position:=0;
{1 Replace user message in hexbuffer and write flash}
Userstring:=edit1.Text;
For i:=0 to 15 Do HexBuffer[i+UserMsgIndex]:=ord(Userstring[i+1]);{send user string in buffer}
Statusbar1.Panels[0].text:='Buffer Loaded!';

{2 check if X-meter ready in Firmware Upgrade mode , read ACK bit (379.6)}
If (inp32($379) and  64 = 0) or bypass = true then
   Begin
   statusbar1.panels[0].text:='X-Meter Connected!';
   setuptimer.enabled:=true;
   {delay 3 sec then start writing}
    end
    Else
    Begin
    MessageDlg('ไม่สามารถติดต่อ X-METER ได้'+#10+#13+'กรุณากดปุ่ม UP+DOWN ค้างไว้หลังการ RESET'+#10+#13+'เพื่อเข้าสู่โมหด UPGRADE FIRMWARE'+#10+#13+'และตรวจสอบว่าได้ต่อสายข้อมูลเรียบร้อยหรือไม่',MTError,[mbOK],0);
    bitbtn1.Enabled:=true;
    trackbar1.Enabled:=true;
    form1.FormShow(sender);
    exit;{exit from process}
    End;
end;
{===========================}
procedure TForm1.CheckBox1Click(Sender: TObject);
begin
If checkbox1.Checked then
 begin
 edit1.Enabled:=true;
 edit1.color:=clyellow;
 bitbtn5.enabled:=true;
 end
 else
 begin
 edit1.enabled:=false;
 edit1.color:=clolive;
 bitbtn5.enabled:=true;
 end;
end;
{--------------}
procedure TForm1.FormShow(Sender: TObject);
var
    i,j:integer;
    bytecount:integer;
    lineread:string;
begin
 {initialize global variable}
 clrb($37A,0);  {prepare for checking X-Meter connecting OK}
 clrb($379,6); {reset checking pin}
 chipreset;
 Gauge1.Position:=0;
{ Gauge1.ForeColor:=clBlue;}
 shape1.Brush.Color:=clGreen;
 bitbtn1.Enabled:=true;
 trackbar1.Enabled:=true;
 bypass:=false;
 speedcontrol:=200*trackbar1.Position;
 for i:=0 to 8191 do hexbuffer[i]:=255;
 for i:=0 to 127 do EEPROM[i]:=255;
{Read constant firmware into Hexbuffer}
bytecount:=0;
i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware0[i])*16+HextoInt(firmware0[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware1[i])*16+HextoInt(firmware1[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware2[i])*16+HextoInt(firmware2[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware3[i])*16+HextoInt(firmware3[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware4[i])*16+HextoInt(firmware4[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware5[i])*16+HextoInt(firmware5[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware6[i])*16+HextoInt(firmware6[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware7[i])*16+HextoInt(firmware7[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware8[i])*16+HextoInt(firmware8[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware9[i])*16+HextoInt(firmware9[i+1]);i:=i+2;inc(bytecount);End;i:=1;

for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware10[i])*16+HextoInt(firmware10[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware11[i])*16+HextoInt(firmware11[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware12[i])*16+HextoInt(firmware12[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware13[i])*16+HextoInt(firmware13[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware14[i])*16+HextoInt(firmware14[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware15[i])*16+HextoInt(firmware15[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware16[i])*16+HextoInt(firmware16[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware17[i])*16+HextoInt(firmware17[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware18[i])*16+HextoInt(firmware18[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware19[i])*16+HextoInt(firmware19[i+1]);i:=i+2;inc(bytecount);End;i:=1;

for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware20[i])*16+HextoInt(firmware20[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware21[i])*16+HextoInt(firmware21[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware22[i])*16+HextoInt(firmware22[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware23[i])*16+HextoInt(firmware23[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware24[i])*16+HextoInt(firmware24[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware25[i])*16+HextoInt(firmware25[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware26[i])*16+HextoInt(firmware26[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware27[i])*16+HextoInt(firmware27[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware28[i])*16+HextoInt(firmware28[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware29[i])*16+HextoInt(firmware29[i+1]);i:=i+2;inc(bytecount);End;i:=1;

for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware30[i])*16+HextoInt(firmware30[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware31[i])*16+HextoInt(firmware31[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware32[i])*16+HextoInt(firmware32[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware33[i])*16+HextoInt(firmware33[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware34[i])*16+HextoInt(firmware34[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware35[i])*16+HextoInt(firmware35[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware36[i])*16+HextoInt(firmware36[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware37[i])*16+HextoInt(firmware37[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware38[i])*16+HextoInt(firmware38[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware39[i])*16+HextoInt(firmware39[i+1]);i:=i+2;inc(bytecount);End;i:=1;

for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware40[i])*16+HextoInt(firmware40[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware41[i])*16+HextoInt(firmware41[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware42[i])*16+HextoInt(firmware42[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware43[i])*16+HextoInt(firmware43[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware44[i])*16+HextoInt(firmware44[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware45[i])*16+HextoInt(firmware45[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware46[i])*16+HextoInt(firmware46[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware47[i])*16+HextoInt(firmware47[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware48[i])*16+HextoInt(firmware48[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware49[i])*16+HextoInt(firmware49[i+1]);i:=i+2;inc(bytecount);End;i:=1;

for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware50[i])*16+HextoInt(firmware50[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware51[i])*16+HextoInt(firmware51[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware52[i])*16+HextoInt(firmware52[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware53[i])*16+HextoInt(firmware53[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware54[i])*16+HextoInt(firmware54[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware55[i])*16+HextoInt(firmware55[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware56[i])*16+HextoInt(firmware56[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware57[i])*16+HextoInt(firmware57[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware58[i])*16+HextoInt(firmware58[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware59[i])*16+HextoInt(firmware59[i+1]);i:=i+2;inc(bytecount);End;i:=1;

for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware60[i])*16+HextoInt(firmware60[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware61[i])*16+HextoInt(firmware61[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware62[i])*16+HextoInt(firmware62[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware63[i])*16+HextoInt(firmware63[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware64[i])*16+HextoInt(firmware64[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware65[i])*16+HextoInt(firmware65[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware66[i])*16+HextoInt(firmware66[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware67[i])*16+HextoInt(firmware67[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware68[i])*16+HextoInt(firmware68[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware69[i])*16+HextoInt(firmware69[i+1]);i:=i+2;inc(bytecount);End;i:=1;

for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware70[i])*16+HextoInt(firmware70[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware71[i])*16+HextoInt(firmware71[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware72[i])*16+HextoInt(firmware72[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware73[i])*16+HextoInt(firmware73[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware74[i])*16+HextoInt(firmware74[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware75[i])*16+HextoInt(firmware75[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware76[i])*16+HextoInt(firmware76[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware77[i])*16+HextoInt(firmware77[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware78[i])*16+HextoInt(firmware78[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware79[i])*16+HextoInt(firmware79[i+1]);i:=i+2;inc(bytecount);End;i:=1;

for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware80[i])*16+HextoInt(firmware80[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware81[i])*16+HextoInt(firmware81[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware82[i])*16+HextoInt(firmware82[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware83[i])*16+HextoInt(firmware83[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware84[i])*16+HextoInt(firmware84[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware85[i])*16+HextoInt(firmware85[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware86[i])*16+HextoInt(firmware86[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware87[i])*16+HextoInt(firmware87[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware88[i])*16+HextoInt(firmware88[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware89[i])*16+HextoInt(firmware89[i+1]);i:=i+2;inc(bytecount);End;i:=1;

for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware90[i])*16+HextoInt(firmware90[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware91[i])*16+HextoInt(firmware91[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware92[i])*16+HextoInt(firmware92[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware93[i])*16+HextoInt(firmware93[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware94[i])*16+HextoInt(firmware94[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware95[i])*16+HextoInt(firmware95[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware96[i])*16+HextoInt(firmware96[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware97[i])*16+HextoInt(firmware97[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware98[i])*16+HextoInt(firmware98[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware99[i])*16+HextoInt(firmware99[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware100[i])*16+HextoInt(firmware100[i+1]);i:=i+2;inc(bytecount);End;i:=1;
for j:=1 to 64 do Begin HexBuffer[bytecount]:=hextoint(firmware101[i])*16+HextoInt(firmware101[i+1]);i:=i+2;inc(bytecount);End;i:=1;
{add more firmware line here}


statusbar1.Panels[0].text:='BUFFER: '+inttostr(bytecount)+' Byte Read';
{show hexbuffer in debug page }
lineread:='';j:=0;
for i:=0 to bytecount Do
 Begin
 lineread:=lineread+Inttohex(HexBuffer[i],2);
 inc(j);
 If j=16 then begin memo1.lines.append('$'+inttohex(i-15,4)+' : '+lineread);j:=0;lineread:='';end;
 end;
memo1.lines.add('=============================================');
Memo1.lines.add('X-METER by Jerry @ThaiMazda3.com');
Memo1.lines.add('http://www.geocities.com/jirakarn_w/xmeter.html');
Memo1.lines.add('E-mail: ahmlite@hotmail.com');

end;
{----------------------}
procedure TForm1.setuptimerTimer(Sender: TObject);
begin
{delay 64 clock}
setuptimer.enabled:=false;
chipenable;
ChipErase;
statusbar1.panels[0].text:='Erasing...';
statusbar1.refresh;
Writetimer.enabled:=true;
end;
{=======================}
procedure TForm1.WriteTimerTimer(Sender: TObject);
var pagecount,k,MISO:byte;
    i,j,complete:integer;
begin
    WriteTimer.enabled:=false;
    Gauge1.Max:=bufferlen*2;
{    Gauge1.maxvalue:=bufferlen*2;}
    pagecount:=0;j:=0;complete:=0;
{========== WRITE PAGE ==================}
Repeat
{Gauge1.forecolor:=clred;}
for i:=1 to 8 Do {page Write cmd}
     Begin
     CAse PageWrite[i] of
     '0':clrb($37A,3);
     '1':setb($37A,3);
     end;{case}
     {clock after 1 bit}
     Clock;
     End; {for j}
{write page address}
If (pagecount and 128) = 128 then setb($37A,3) else clrb($37A,3);Clock;
If (pagecount and 64) = 64 then setb($37A,3) else clrb($37A,3);Clock;
If (pagecount and 32) = 32 then setb($37A,3) else clrb($37A,3);Clock;
If (pagecount and 16) = 16 then setb($37A,3) else clrb($37A,3);Clock;
If (pagecount and 8) = 8 then setb($37A,3) else clrb($37A,3);Clock;
If (pagecount and 4) = 4 then setb($37A,3) else clrb($37A,3);Clock;
If (pagecount and 2) = 2 then setb($37A,3) else clrb($37A,3);Clock;
If (pagecount and 1) = 1 then setb($37A,3) else clrb($37A,3);Clock;

for k:=0 to 255 do {write data}
Begin
If (HexBuffer[j] and 128) = 128 then setb($37A,3) else clrb($37A,3);Clock;
If (HexBuffer[j] and 64) = 64 then setb($37A,3) else clrb($37A,3);Clock;
If (HexBuffer[j] and 32) = 32 then setb($37A,3) else clrb($37A,3);Clock;
If (HexBuffer[j] and 16) = 16 then setb($37A,3) else clrb($37A,3);Clock;
If (HexBuffer[j] and 8) = 8 then setb($37A,3) else clrb($37A,3);Clock;
If (HexBuffer[j] and 4) = 4 then setb($37A,3) else clrb($37A,3);Clock;
If (HexBuffer[j] and 2) = 2 then setb($37A,3) else clrb($37A,3);Clock;
If (HexBuffer[j] and 1) = 1 then setb($37A,3) else clrb($37A,3);Clock;
Gauge1.Position:=complete;
{Gauge1.Progress:=complete;}
statusbar1.panels[0].text:= 'Writing:    '+inttostr(j)+' / '+inttostr(bufferlen)+' [ '+inttostr(j*100 div bufferlen)+'% ]';
statusbar1.Refresh;
inc(j);inc(complete);
end;
{========== READ PAGE ==================}
{Verify Data}
j:=j-256;
for i:=0 to 150*speedcontrol do begin end; {delay}
{Repeat}
for i:=1 to 8 Do {page read cmd}
     Begin
     CAse PageRead[i] of
     '0':clrb($37A,3);
     '1':setb($37A,3);
     end;{case}
     {clock after 1 bit}
     Clock;
     End; {for j}
{read page address}
If (pagecount and 128) = 128 then setb($37A,3) else clrb($37A,3);Clock;
If (pagecount and 64) = 64 then setb($37A,3) else clrb($37A,3);Clock;
If (pagecount and 32) = 32 then setb($37A,3) else clrb($37A,3);Clock;
If (pagecount and 16) = 16 then setb($37A,3) else clrb($37A,3);Clock;
If (pagecount and 8) = 8 then setb($37A,3) else clrb($37A,3);Clock;
If (pagecount and 4) = 4 then setb($37A,3) else clrb($37A,3);Clock;
If (pagecount and 2) = 2 then setb($37A,3) else clrb($37A,3);Clock;
If (pagecount and 1) = 1 then setb($37A,3) else clrb($37A,3);Clock;

for k:=0 to 255 do {read data}
Begin
If (Inp32($379) and 64) = 64 then MISO:=128 else MISO:=0;Clock;
If (Inp32($379) and 64) = 64 then MISO:=MISO+64 else MISO:=MISO+0;Clock;
If (Inp32($379) and 64) = 64 then MISO:=MISO+32 else MISO:=MISO+0;Clock;
If (Inp32($379) and 64) = 64 then MISO:=MISO+16 else MISO:=MISO+0;Clock;
If (Inp32($379) and 64) = 64 then MISO:=MISO+8 else MISO:=MISO+0;Clock;
If (Inp32($379) and 64) = 64 then MISO:=MISO+4 else MISO:=MISO+0;Clock;
If (Inp32($379) and 64) = 64 then MISO:=MISO+2 else MISO:=MISO+0;Clock;
If (Inp32($379) and 64) = 64 then MISO:=MISO+1 else MISO:=MISO+0;Clock;
Gauge1.Position:=complete;
{Gauge1.Progress:= complete;}
statusbar1.panels[0].text:= 'Verifying: '+inttostr(j)+' / '+inttostr(bufferlen)+' [ '+inttostr(j*100 div bufferlen)+'% ]';
statusbar1.Refresh;
If MISO<>Hexbuffer[j] then {error checking}
 Begin ChipEnable;ChipErase;{verify fail then erase firmware first}
 If MessageDlg('มีความผิดพลาดระหว่างการลงโปรแกรม!'+#10+#13+#10+#13+'คุณต้องการลง Firmware ใหม่อีกครั้งหรือไม่ ?',mtError,[mbYes,mbAbort],0)
      = mrYes then begin ChipReset;form1.FormShow(sender);exit end else begin chipreset;halt;end;
 End;{MISO<>HexBuffer}
inc(j);inc(complete);
end;{for k=0}
inc(pagecount);
until j>= bufferlen; {end verifying loop}
{==========write lock bit all mode 1,2,3,4 in sequence==============}
{Each mode have to reset & enable chip before write lock bit again}
statusbar1.panels[0].text:= 'Error Checking...Please Wait!';
statusbar1.Refresh;
for i:=1 to 32 Do     {Lock Bit1}
Begin
Case LockBit2[i] of
     '0':clrb($37A,3);
     '1':setb($37A,3);
     end;{case}
     {clock after 1 bit}
clock;
end;
chipenable;
for i:=1 to 32 Do
Begin
Case LockBit3[i] of
     '0':clrb($37A,3);
     '1':setb($37A,3);
     end;{case}
     {clock after 1 bit}
clock;
end;
chipenable;
for i:=1 to 32 Do
Begin
Case LockBit4[i] of
     '0':clrb($37A,3);
     '1':setb($37A,3);
     end;{case}
     {clock after 1 bit}
clock;
end;
{==========Read Lock bit =================}
for i:=1 to 24 Do {send read lock bit command}
Begin
Case ReadLockBit[i] of
     '0':clrb($37A,3);
     '1':setb($37A,3);
     end;{case}
     {clock after 1 bit}
clock;
end;
{Read Lock bit 1 Byte}
If (Inp32($379) and 64) = 64 then MISO:=128 else MISO:=0;Clock;
If (Inp32($379) and 64) = 64 then MISO:=MISO+64 else MISO:=MISO+0;Clock;
If (Inp32($379) and 64) = 64 then MISO:=MISO+32 else MISO:=MISO+0;Clock;
If (Inp32($379) and 64) = 64 then MISO:=MISO+16 else MISO:=MISO+0;Clock;
If (Inp32($379) and 64) = 64 then MISO:=MISO+8 else MISO:=MISO+0;Clock;
If (Inp32($379) and 64) = 64 then MISO:=MISO+4 else MISO:=MISO+0;Clock;
If (Inp32($379) and 64) = 64 then MISO:=MISO+2 else MISO:=MISO+0;Clock;
If (Inp32($379) and 64) = 64 then MISO:=MISO+1 else MISO:=MISO+0;Clock;
{==== Check Lock Bit OK or not ========}
If MISO = $7C then
  Begin{== Lock Bit success finish ==== }
    shape1.Brush.Color:=clLime;
    setb($37A,3); {set MOSI hi}
    Statusbar1.Panels[0].text:='Upgrade Finished! ->'+Inttohex(MISO,2);
    statusbar1.Refresh;
    bitbtn1.enabled:=true;
    trackbar1.Enabled:=true;
    beep;
    If MessageDlg('การ Upgrade Firmware เสร็จสิ้น!',MTInformation,[mbOK],0)=mrOK then clrb($37A,1);{set RESET low program finish};
  End
Else
  Begin shape1.Brush.Color:=clGreen;
{lock bit not success then erase chip}
  ChipEnable;
  ChipErase;
  statusbar1.panels[0].text:='Error!';
  statusbar1.Refresh;
  beep;
  If MessageDlg('การโปรแกรมผิดพลาดในขั้นตอนสุดท้าย'+#10+#13+'กรุณาทำใหม่อีกครั้ง!',MTError,[mbOK],0)=mrOK then
     Begin chipreset;form1.FormShow(sender);exit end;
  End; {else If MISO = $7C}
end;{Procedure}
{===============}
procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
chipreset;
end;
{================}
procedure TForm1.StatusBar1DblClick(Sender: TObject);
begin
bypass:=true;
end;
{=================}
procedure TForm1.TrackBar1Change(Sender: TObject);
begin
speedcontrol:=200*trackbar1.Position;
end;
{============= Set Limit ==================}
Procedure ShowEEPROM;
var i:byte;
    s:string;
Begin
for i:=0 to 15 do
s:=s+inttohex(EEPROM[i],2);
form1.memo4.Lines.Text:='00-0F: '+s;
s:='';
for i:=16 to 31 do
s:=s+inttohex(EEPROM[i],2);
form1.memo4.Lines.Add('10-1F: '+s);
s:='';
for i:=32 to 47 do
s:=s+inttohex(EEPROM[i],2);
form1.memo4.Lines.Add('20-2F: '+s);
s:='';
for i:=48 to 63 do
s:=s+inttohex(EEPROM[i],2);
form1.memo4.Lines.Add('30-3F: '+s);
s:='';
for i:=64 to 79 do
s:=s+inttohex(EEPROM[i],2);
form1.memo4.Lines.Add('40-4F: '+s);
end;

procedure TForm1.BitBtn3Click(Sender: TObject);
var i:integer;
     k:byte;
     S:string[4];
begin
Panel1.visible:=false;Panel2.visible:=false;Panel3.Visible:=true;memo2.visible:=false;
Gauge1.Position:=0;
Gauge1.Max:=127;
{Gauge1.Progress:=0;
Gauge1.ForeColor:=clBlue;
Gauge1.MaxValue:=127;    }
trackbar1.enabled:=false;
chipreset;
clrb($37A,0);
statusbar1.panels[0].text:= 'Default Limitted Value Loaded...';
statusbar1.Refresh;
{initialize table}
stringgrid1.Cells[0,0]:='Parameter ID';
stringgrid1.Cells[1,0]:='Limit Value';
stringgrid1.Cells[2,0]:='Unit';
stringgrid1.Cells[0,1]:='Calculated Engine Load';
stringgrid1.Cells[2,1]:='%';
stringgrid1.Cells[0,2]:='Coolant Temperature';
stringgrid1.Cells[2,2]:='ฐc';
stringgrid1.Cells[0,3]:='Short Term Fuel Trim 1';
stringgrid1.Cells[2,3]:='%';
stringgrid1.Cells[0,4]:='Long Term Fuel Trim 1';
stringgrid1.Cells[2,4]:='%';
stringgrid1.Cells[0,5]:='Fuel Pressure';
stringgrid1.Cells[2,5]:='kPa';
stringgrid1.Cells[0,6]:='Manifold Air Pressure';
stringgrid1.Cells[2,6]:='kPa';
stringgrid1.Cells[0,7]:='Engine Speed';
stringgrid1.Cells[2,7]:='RPM';
stringgrid1.Cells[0,8]:='Vehicle Speed';
stringgrid1.Cells[2,8]:='km/h';
stringgrid1.Cells[0,9]:='Ignition Advanced Timing';
stringgrid1.Cells[2,9]:='ฐ';
stringgrid1.Cells[0,10]:='Intake Air Temperature';
stringgrid1.Cells[2,10]:='ฐc';
stringgrid1.Cells[0,11]:='Air Flow';
stringgrid1.Cells[2,11]:='g/sec';
stringgrid1.Cells[0,12]:='Throttle Position';
stringgrid1.Cells[2,12]:='%';
stringgrid1.Cells[0,13]:='Front Heated O2 Sensor Volt';
stringgrid1.Cells[2,13]:='Volt';
stringgrid1.Cells[0,14]:='Rear Heated O2 Sensor Volt';
stringgrid1.Cells[2,14]:='Volt';
stringgrid1.Cells[0,15]:='Fuel Rail Pressure';
stringgrid1.Cells[2,15]:='MPa';
stringgrid1.Cells[0,16]:='Commanded EGR';
stringgrid1.Cells[2,16]:='%';
stringgrid1.Cells[0,17]:='EGR Error';
stringgrid1.Cells[2,17]:='%';
stringgrid1.Cells[0,18]:='Commanded Evaporative Purge';
stringgrid1.Cells[2,18]:='%';
stringgrid1.Cells[0,19]:='Fuel Level';
stringgrid1.Cells[2,19]:='%';
stringgrid1.Cells[0,20]:='Barometric Pressure';
stringgrid1.Cells[2,20]:='kPa';
stringgrid1.Cells[0,21]:='Catalytic 1 Temperature';
stringgrid1.Cells[2,21]:='ฐc';
stringgrid1.Cells[0,22]:='Catalytic 2 Temperature';
stringgrid1.Cells[2,22]:='ฐc';
stringgrid1.Cells[0,23]:='PCM Voltage';
stringgrid1.Cells[2,23]:='Volt';
stringgrid1.Cells[0,24]:='Absolute Engine Load';
stringgrid1.Cells[2,24]:='%';
stringgrid1.Cells[0,25]:='Command Equivalent Ratio';
stringgrid1.Cells[2,25]:='None';
stringgrid1.Cells[0,26]:='Relative Throttle Position';
stringgrid1.Cells[2,26]:='%';
stringgrid1.Cells[0,27]:='Ambient Air Temperature';
stringgrid1.Cells[2,27]:='ฐc';
stringgrid1.Cells[0,28]:='Transmission Fluid Temperature';
stringgrid1.Cells[2,28]:='ฐc';

{Load default value to EEPROM buffer}

k:=0;
for i:=0 to 15 do
begin
EEPROM[i]:= HextoInt(EEPROM0[k+1])*16+HextoInt(EEPROM0[k+2]);
k:=k+2;
end;
k:=0;
for i:=16 to 31 do
begin
EEPROM[i]:= HextoInt(EEPROM1[k+1])*16+HextoInt(EEPROM1[k+2]);
k:=k+2;
end;
k:=0;
for i:=32 to 47 do
begin
EEPROM[i]:= HextoInt(EEPROM2[k+1])*16+HextoInt(EEPROM2[k+2]);
k:=k+2;
end;
k:=0;
for i:=48 to 63 do
begin
EEPROM[i]:= HextoInt(EEPROM3[k+1])*16+HextoInt(EEPROM3[k+2]);
k:=k+2;
end;
k:=0;
for i:=64 to 79 do
begin
EEPROM[i]:= HextoInt(EEPROM4[k+1])*16+HextoInt(EEPROM4[k+2]);
k:=k+2;
end;{load data to EEPROM buffer ready}
{show raw data in table}
stringgrid1.Cells[1,1]:=inttostr(EEPROM[$4]*100 div 255);
stringgrid1.Cells[1,2]:=inttostr(EEPROM[$5]-40);
stringgrid1.Cells[1,3]:=inttostr((EEPROM[$6]*$64 div $80) - $64);
stringgrid1.Cells[1,4]:=inttostr((EEPROM[$7]*$64 div $80) - $64);
stringgrid1.Cells[1,5]:=inttostr(EEPROM[$A]);
stringgrid1.Cells[1,6]:=inttostr(EEPROM[$B]);
stringgrid1.Cells[1,7]:=inttostr(EEPROM[$C]*256 div 4);
stringgrid1.Cells[1,8]:=inttostr(EEPROM[$D]);
stringgrid1.Cells[1,9]:=inttostr(EEPROM[$E] div 2 - 64);
stringgrid1.Cells[1,10]:=inttostr(EEPROM[$F]-40);
stringgrid1.Cells[1,11]:=inttostr(EEPROM[$10]*256 div 100);
stringgrid1.Cells[1,12]:=inttostr(EEPROM[$11]*100 div 255);
STR((EEPROM[$14]/200):0:2,S);
stringgrid1.Cells[1,13]:=s;
STR((EEPROM[$15]/200):0:2,S);
stringgrid1.Cells[1,14]:=s;
stringgrid1.Cells[1,15]:=inttostr(EEPROM[$23]*256 div 100);
stringgrid1.Cells[1,16]:=inttostr(EEPROM[$2C]*100 div 255);
stringgrid1.Cells[1,17]:=inttostr(EEPROM[$2D]*100 div 255);
stringgrid1.Cells[1,18]:=inttostr(EEPROM[$2E]*100 div 255);
stringgrid1.Cells[1,19]:=inttostr(EEPROM[$2F]*100 div 255);
stringgrid1.Cells[1,20]:=inttostr(EEPROM[$33]);
STR((EEPROM[$3C]*256 / 10-40):0:1,S);
stringgrid1.Cells[1,21]:=s;
STR((EEPROM[$3D]*256 / 10-40):0:1,S);
stringgrid1.Cells[1,22]:=s;
STR((EEPROM[$42]*256 / 1000):0:2,S);
stringgrid1.Cells[1,23]:=s;
stringgrid1.Cells[1,24]:=inttostr(EEPROM[$43]*100 div 255);
STR((EEPROM[$44]*256 / 32768):0:2,S);
stringgrid1.Cells[1,25]:=s;
stringgrid1.Cells[1,26]:=inttostr(EEPROM[$45]*100 div 255);
stringgrid1.Cells[1,27]:=inttostr(EEPROM[$46]-40);
STR((EEPROM[$22]*256 / 10-40):0:1,S);
stringgrid1.Cells[1,28]:=s;

showeeprom;
end;



procedure TForm1.UpDown1Click(Sender: TObject; Button: TUDBtnType);
var s:string;
begin
Case Stringgrid1.row of
1:Begin EEPROM[$4]:=updown1.position;
stringgrid1.Cells[1,1]:=inttostr(EEPROM[$4]*100 div 255);end;
2:Begin EEPROM[$5]:=updown1.position;
stringgrid1.Cells[1,2]:=inttostr(EEPROM[$5]-40);end;
3:Begin EEPROM[$6]:=updown1.position;
stringgrid1.Cells[1,3]:=inttostr((EEPROM[$6]*$64 div $80) - $64);end;
4:Begin EEPROM[$7]:=updown1.position;
stringgrid1.Cells[1,4]:=inttostr((EEPROM[$7]*$64 div $80) - $64);end;
5:Begin EEPROM[$A]:=updown1.position;
stringgrid1.Cells[1,5]:=inttostr(EEPROM[$A]);end;
6:Begin EEPROM[$B]:=updown1.position;
stringgrid1.Cells[1,6]:=inttostr(EEPROM[$B]);end;
7:Begin EEPROM[$C]:=updown1.position;
stringgrid1.Cells[1,7]:=inttostr(EEPROM[$C]*256 div 4);end;
8:Begin EEPROM[$D]:=updown1.position;
stringgrid1.Cells[1,8]:=inttostr(EEPROM[$D]);end;
9:Begin EEPROM[$E]:=updown1.position;
stringgrid1.Cells[1,9]:=inttostr(EEPROM[$E] div 2 - 64);end;
10:Begin EEPROM[$F]:=updown1.position;
stringgrid1.Cells[1,10]:=inttostr(EEPROM[$F]-40);end;
11:Begin EEPROM[$10]:=updown1.position;
stringgrid1.Cells[1,11]:=inttostr(EEPROM[$10]*256 div 100);end;
12:Begin EEPROM[$11]:=updown1.position;
stringgrid1.Cells[1,12]:=inttostr(EEPROM[$11]*100 div 255);end;
13:Begin EEPROM[$14]:=updown1.position;
STR((EEPROM[$14]/200):0:2,S);
stringgrid1.Cells[1,13]:=s;end;
14:Begin EEPROM[$15]:=updown1.position;
STR((EEPROM[$15]/200):0:2,S);
stringgrid1.Cells[1,14]:=s;end;
15:Begin EEPROM[$23]:=updown1.position;
stringgrid1.Cells[1,15]:=inttostr(EEPROM[$23]*256 div 100);end;

16:Begin EEPROM[$2C]:=updown1.position;
stringgrid1.Cells[1,16]:=inttostr(EEPROM[$2C]*100 div 255);end;
17:Begin EEPROM[$2D]:=updown1.position;
stringgrid1.Cells[1,17]:=inttostr(EEPROM[$2D]*100 div 255);end;
18:Begin EEPROM[$2E]:=updown1.position;
stringgrid1.Cells[1,18]:=inttostr(EEPROM[$2E]*100 div 255);end;
19:Begin EEPROM[$2F]:=updown1.position;
stringgrid1.Cells[1,19]:=inttostr(EEPROM[$2F]*100 div 255);end;
20:Begin EEPROM[$33]:=updown1.position;
stringgrid1.Cells[1,20]:=inttostr(EEPROM[$33]);end;
21:Begin EEPROM[$3C]:=updown1.position;
STR((EEPROM[$3C]*256 / 10-40):0:1,S);
stringgrid1.Cells[1,21]:=s;end;
22:Begin EEPROM[$3D]:=updown1.position;
STR((EEPROM[$3D]*256 / 10-40):0:1,S);
stringgrid1.Cells[1,22]:=s;end;
23:Begin EEPROM[$42]:=updown1.position;
STR((EEPROM[$42]*256 / 1000):0:2,S);
stringgrid1.Cells[1,23]:=s;end;
24:Begin EEPROM[$43]:=updown1.position;
stringgrid1.Cells[1,24]:=inttostr(EEPROM[$43]*100 div 255);end;
25:Begin EEPROM[$44]:=updown1.position;
STR((EEPROM[$44]*256 / 32768):0:2,S);
stringgrid1.Cells[1,25]:=s;end;
26:Begin EEPROM[$45]:=updown1.position;
stringgrid1.Cells[1,26]:=inttostr(EEPROM[$45]*100 div 255);end;
27:Begin EEPROM[$46]:=updown1.position;
stringgrid1.Cells[1,27]:=inttostr(EEPROM[$46]-40);end;
28:Begin EEPROM[$22]:=updown1.position;
STR((EEPROM[$22]*256 / 10-40):0:1,S);
stringgrid1.Cells[1,28]:=s;end;
end;{case}
showeeprom;
end;

procedure TForm1.StringGrid1SelectCell(Sender: TObject; Col, Row: Integer;
  var CanSelect: Boolean);
begin
Case Row of
1:updown1.position:=EEPROM[$4];
2:updown1.position:=EEPROM[$5];
3:updown1.position:=EEPROM[$6];
4:updown1.position:=EEPROM[$7];
5:updown1.position:=EEPROM[$A];
6:updown1.position:=EEPROM[$B];
7:updown1.position:=EEPROM[$C];
8:updown1.position:=EEPROM[$D];
9:updown1.position:=EEPROM[$E];
10:updown1.position:=EEPROM[$F];
11:updown1.position:=EEPROM[$10];
12:updown1.position:=EEPROM[$11];
13:updown1.position:=EEPROM[$14];
14:updown1.position:=EEPROM[$15];
15:updown1.position:=EEPROM[$23];
16:updown1.position:=EEPROM[$2C];
17:updown1.position:=EEPROM[$2D];
18:updown1.position:=EEPROM[$2E];
19:updown1.position:=EEPROM[$2F];
20:updown1.position:=EEPROM[$33];
21:updown1.position:=EEPROM[$3C];
22:updown1.position:=EEPROM[$3D];
23:updown1.position:=EEPROM[$42];
24:updown1.position:=EEPROM[$43];
25:updown1.position:=EEPROM[$44];
26:updown1.position:=EEPROM[$45];
27:updown1.position:=EEPROM[$46];
28:updown1.position:=EEPROM[$22];
ENd;{case}
end;

procedure TForm1.BitBtn4Click(Sender: TObject);{dump data to eeprom}
var i:byte;
begin
If (inp32($379) and  64 = 0)=false then
 begin
 MessageDlg('ไม่สามารถติดต่อ X-METER ได้'+#10+#13+'กรุณากดปุ่ม MENU ค้างไว้หลังการ RESET'+#10+#13+'เพื่อเข้าสู่โมหด SET LIMITTED VALUE'+#10+#13+'และตรวจสอบว่าได้ต่อสายข้อมูลเรียบร้อยหรือไม่',MTError,[mbOK],0);
 chipreset;
 Exit;
 end else
 Begin
 bitbtn3.enabled:=false;
 setb($37A,0);  {sck low tell X-Meter connecting OK}
statusbar1.panels[0].text:= 'Sending Limitted Value to X-METER';
statusbar1.Refresh;
for i:=1 to 127 do {write data}
Begin {MSB to LSB}
If (EEPROM[i] and 128) = 128 then setb($37A,3) else clrb($37A,3);eepromclock;
If (EEPROM[i] and 64) = 64 then setb($37A,3) else clrb($37A,3);eepromclock;
If (EEPROM[i] and 32) = 32 then setb($37A,3) else clrb($37A,3);eepromclock;
If (EEPROM[i] and 16) = 16 then setb($37A,3) else clrb($37A,3);eepromclock;
If (EEPROM[i] and 8) = 8 then setb($37A,3) else clrb($37A,3);eepromclock;
If (EEPROM[i] and 4) = 4 then setb($37A,3) else clrb($37A,3);eepromclock;
If (EEPROM[i] and 2) = 2 then setb($37A,3) else clrb($37A,3);eepromclock;
If (EEPROM[i] and 1) = 1 then setb($37A,3) else clrb($37A,3);eepromclock;
Gauge1.Position:=i;
{Gauge1.Progress:=i;}
end;{for}
statusbar1.panels[0].text:= 'Setting Complete!...';
statusbar1.Refresh;
trackbar1.enabled:=true;
 bitbtn3.enabled:=true;
 End;{If not}
end;

procedure TForm1.BitBtn6Click(Sender: TObject);
begin
 Panel1.visible:=false;
 Panel2.visible:=false;
 Panel3.Visible:=false;
 memo2.visible:=true;
end;

procedure TForm1.m3timerTimer(Sender: TObject);
begin
image2.Left:=image2.left-5;
if image2.left<10 then m3timer.enabled:=false;
LoadDefaultLogoBTN.Click;
end;
{------------ Logo Editor --------------------------}
Procedure LogoCodeShow;{show code in memo3 }
var j,k:byte;
temp1:string;
begin
 form1.memo3.Clear;
 for k:=0 to 5 do {char 1 - 6}
 begin
 for j:=0 to 7 do {CGUL}
 temp1:= temp1+inttohex(HexBuffer[UserLogoIndex+j+k*10],0)+',';
 if k=0 then form1.memo3.Lines.Text:=temp1
    else form1.memo3.lines.add(temp1);
 temp1:='';
 end;
end;
{load logo}

procedure TForm1.LoadDefaultLogoBTNClick(Sender: TObject);
var temp1,temp2,i,j,k:integer;
begin
drawgrid1.Canvas.Pen.Width:=4;
drawgrid1.Canvas.Pen.Color:=clblack;
drawgrid2.Canvas.Pen.Width:=4;
drawgrid2.Canvas.Pen.Color:=clblack;
drawgrid3.Canvas.Pen.Width:=4;
drawgrid3.Canvas.Pen.Color:=clblack;
drawgrid4.Canvas.Pen.Width:=4;
drawgrid4.Canvas.Pen.Color:=clblack;
drawgrid5.Canvas.Pen.Width:=4;
drawgrid5.Canvas.Pen.Color:=clblack;
drawgrid6.Canvas.Pen.Width:=4;
drawgrid6.Canvas.Pen.Color:=clblack;
k:=1;
for i:=0 to 59 do  {load Mazda Logo in to buffer}
 Begin
 HexBuffer[UserLogoindex+i]:=HextoInt(MazdaLogo[k])*16+HextoInt(MazdaLogo[k+1]);
 k:=k+2;
 end;
for k:=0 to 5 do {char 1 - 6}
for j:=0 to 7 do {CGUL}
begin
 temp1:= HexBuffer[UserLogoIndex+j+k*10];
  for i:=0 to 4 do  {row}
  begin
  temp2:= round(power(2,4-i));
  if (temp1 and temp2) =  temp2 then
   case k of
   0:drawgrid1.Canvas.Rectangle(i*10+2,j*10+2,i*10+8,j*10+8);
   1:drawgrid2.Canvas.Rectangle(i*10+2,j*10+2,i*10+8,j*10+8);
   2:drawgrid3.Canvas.Rectangle(i*10+2,j*10+2,i*10+8,j*10+8);
   3:drawgrid4.Canvas.Rectangle(i*10+2,j*10+2,i*10+8,j*10+8);
   4:drawgrid5.Canvas.Rectangle(i*10+2,j*10+2,i*10+8,j*10+8);
   5:drawgrid6.Canvas.Rectangle(i*10+2,j*10+2,i*10+8,j*10+8);
   end;{case}
   end;{for i}
end;{for j}
logocodeshow;

end;
{bit 0 }
procedure TForm1.DrawGrid1Click(Sender: TObject);
var temp2:byte;
begin
temp2:= round(power(2,4-drawgrid1.col));
drawgrid1.Canvas.Pen.Color:=clolive;
drawgrid1.Canvas.Pen.Width:=4;
Hexbuffer[userlogoindex+drawgrid1.row]:= Hexbuffer[userlogoindex+drawgrid1.row] and (31-temp2);
drawgrid1.Canvas.Rectangle(drawgrid1.Col*10+2,drawgrid1.Row*10+2,drawgrid1.Col*10+8,drawgrid1.Row*10+8);
logocodeshow;
end;

procedure TForm1.DrawGrid2Click(Sender: TObject);
var temp2:byte;
begin
temp2:= round(power(2,4-drawgrid2.col));
drawgrid2.Canvas.Pen.Color:=clolive;
drawgrid2.Canvas.Pen.Width:=4;
Hexbuffer[userlogoindex+10+drawgrid2.row]:= Hexbuffer[userlogoindex+10+drawgrid2.row] and (31-temp2);
drawgrid2.Canvas.Rectangle(drawgrid2.Col*10+2,drawgrid2.Row*10+2,drawgrid2.Col*10+8,drawgrid2.Row*10+8);
logocodeshow;
end;
procedure TForm1.DrawGrid3Click(Sender: TObject);
var temp2:byte;
begin
temp2:= round(power(2,4-drawgrid3.col));
drawgrid3.Canvas.Pen.Color:=clolive;
drawgrid3.Canvas.Pen.Width:=4;
Hexbuffer[userlogoindex+20+drawgrid3.row]:= Hexbuffer[userlogoindex+20+drawgrid3.row] and (31-temp2);
drawgrid3.Canvas.Rectangle(drawgrid3.Col*10+2,drawgrid3.Row*10+2,drawgrid3.Col*10+8,drawgrid3.Row*10+8);
logocodeshow;
end;

procedure TForm1.DrawGrid4Click(Sender: TObject);
var temp2:byte;
begin
temp2:= round(power(2,4-drawgrid4.col));
drawgrid4.Canvas.Pen.Color:=clolive;
drawgrid4.Canvas.Pen.Width:=4;
Hexbuffer[userlogoindex+30+drawgrid4.row]:= Hexbuffer[userlogoindex+30+drawgrid4.row] and (31-temp2);
drawgrid4.Canvas.Rectangle(drawgrid4.Col*10+2,drawgrid4.Row*10+2,drawgrid4.Col*10+8,drawgrid4.Row*10+8);
logocodeshow;
end;
procedure TForm1.DrawGrid5Click(Sender: TObject);
var temp2:byte;
begin
temp2:= round(power(2,4-drawgrid5.col));
drawgrid5.Canvas.Pen.Color:=clolive;
drawgrid5.Canvas.Pen.Width:=4;
Hexbuffer[userlogoindex+40+drawgrid5.row]:= Hexbuffer[userlogoindex+40+drawgrid5.row] and (31-temp2);
drawgrid5.Canvas.Rectangle(drawgrid5.Col*10+2,drawgrid5.Row*10+2,drawgrid5.Col*10+8,drawgrid5.Row*10+8);
logocodeshow;
end;
procedure TForm1.DrawGrid6Click(Sender: TObject);
var temp2:byte;
begin
temp2:= round(power(2,4-drawgrid6.col));
drawgrid6.Canvas.Pen.Color:=clolive;
drawgrid6.Canvas.Pen.Width:=4;
Hexbuffer[userlogoindex+50+drawgrid6.row]:= Hexbuffer[userlogoindex+50+drawgrid6.row] and (31-temp2);
drawgrid6.Canvas.Rectangle(drawgrid6.Col*10+2,drawgrid6.Row*10+2,drawgrid6.Col*10+8,drawgrid6.Row*10+8);
logocodeshow;
end;
{======== bit 1}
procedure TForm1.DrawGrid1DblClick(Sender: TObject);
var temp2:byte;
begin
temp2:= round(power(2,4-drawgrid1.col));
drawgrid1.Canvas.Pen.Color:=clblack;
drawgrid1.Canvas.Pen.Width:=4;
Hexbuffer[userlogoindex+drawgrid1.row]:= Hexbuffer[userlogoindex+drawgrid1.row] or temp2;
drawgrid1.Canvas.Rectangle(drawgrid1.Col*10+2,drawgrid1.Row*10+2,drawgrid1.Col*10+8,drawgrid1.Row*10+8);
logocodeshow;
end;
procedure TForm1.DrawGrid2DblClick(Sender: TObject);
var temp2:byte;
begin
temp2:= round(power(2,4-drawgrid2.col));
drawgrid2.Canvas.Pen.Color:=clblack;
drawgrid2.Canvas.Pen.Width:=4;
Hexbuffer[userlogoindex+10+drawgrid2.row]:= Hexbuffer[userlogoindex+10+drawgrid2.row] or temp2;
drawgrid2.Canvas.Rectangle(drawgrid2.Col*10+2,drawgrid2.Row*10+2,drawgrid2.Col*10+8,drawgrid2.Row*10+8);
logocodeshow;
end;
procedure TForm1.DrawGrid3DblClick(Sender: TObject);
var temp2:byte;
begin
temp2:= round(power(2,4-drawgrid3.col));
drawgrid3.Canvas.Pen.Color:=clblack;
drawgrid3.Canvas.Pen.Width:=4;
Hexbuffer[userlogoindex+20+drawgrid3.row]:= Hexbuffer[userlogoindex+20+drawgrid3.row] or temp2;
drawgrid3.Canvas.Rectangle(drawgrid3.Col*10+2,drawgrid3.Row*10+2,drawgrid3.Col*10+8,drawgrid3.Row*10+8);
logocodeshow;
end;

procedure TForm1.DrawGrid4DblClick(Sender: TObject);
var temp2:byte;
begin
temp2:= round(power(2,4-drawgrid4.col));
drawgrid4.Canvas.Pen.Color:=clblack;
drawgrid4.Canvas.Pen.Width:=4;
Hexbuffer[userlogoindex+30+drawgrid4.row]:= Hexbuffer[userlogoindex+30+drawgrid4.row] or temp2;
drawgrid4.Canvas.Rectangle(drawgrid4.Col*10+2,drawgrid4.Row*10+2,drawgrid4.Col*10+8,drawgrid4.Row*10+8);
logocodeshow;
end;
procedure TForm1.DrawGrid5DblClick(Sender: TObject);
var temp2:byte;
begin
temp2:= round(power(2,4-drawgrid5.col));
drawgrid5.Canvas.Pen.Color:=clblack;
drawgrid5.Canvas.Pen.Width:=4;
Hexbuffer[userlogoindex+40+drawgrid5.row]:= Hexbuffer[userlogoindex+40+drawgrid5.row] or temp2;
drawgrid5.Canvas.Rectangle(drawgrid5.Col*10+2,drawgrid5.Row*10+2,drawgrid5.Col*10+8,drawgrid5.Row*10+8);
logocodeshow;
end;
procedure TForm1.DrawGrid6DblClick(Sender: TObject);
var temp2:byte;
begin
temp2:= round(power(2,4-drawgrid6.col));
drawgrid6.Canvas.Pen.Color:=clblack;
drawgrid6.Canvas.Pen.Width:=4;
Hexbuffer[userlogoindex+50+drawgrid6.row]:= Hexbuffer[userlogoindex+50+drawgrid6.row] or temp2;
drawgrid6.Canvas.Rectangle(drawgrid6.Col*10+2,drawgrid6.Row*10+2,drawgrid6.Col*10+8,drawgrid6.Row*10+8);
logocodeshow;
end;

procedure TForm1.clearlogobtnClick(Sender: TObject);{clear logo to empty}
var i,j,k:integer;
begin
drawgrid1.Canvas.Pen.Width:=4;
drawgrid1.Canvas.Pen.Color:=clolive;
drawgrid2.Canvas.Pen.Width:=4;
drawgrid2.Canvas.Pen.Color:=clolive;
drawgrid3.Canvas.Pen.Width:=4;
drawgrid3.Canvas.Pen.Color:=clolive;
drawgrid4.Canvas.Pen.Width:=4;
drawgrid4.Canvas.Pen.Color:=clolive;
drawgrid5.Canvas.Pen.Width:=4;
drawgrid5.Canvas.Pen.Color:=clolive;
drawgrid6.Canvas.Pen.Width:=4;
drawgrid6.Canvas.Pen.Color:=clolive;
for k:=0 to 5 do {char 1 - 6}
for j:=0 to 7 do {CGUL}
begin
 HexBuffer[UserLogoIndex+j+k*10]:=$00;
  for i:=0 to 4 do  {row}
   case k of
   0:drawgrid1.Canvas.Rectangle(i*10+2,j*10+2,i*10+8,j*10+8);
   1:drawgrid2.Canvas.Rectangle(i*10+2,j*10+2,i*10+8,j*10+8);
   2:drawgrid3.Canvas.Rectangle(i*10+2,j*10+2,i*10+8,j*10+8);
   3:drawgrid4.Canvas.Rectangle(i*10+2,j*10+2,i*10+8,j*10+8);
   4:drawgrid5.Canvas.Rectangle(i*10+2,j*10+2,i*10+8,j*10+8);
   5:drawgrid6.Canvas.Rectangle(i*10+2,j*10+2,i*10+8,j*10+8);
   end;{case}

end;{for j}
logocodeshow;
end;



procedure TForm1.BlinkTimerTimer(Sender: TObject);
begin
if shape1.Brush.Color = clpurple then shape1.Brush.Color:=clFuchsia
else shape1.Brush.Color:=clpurple;
end;

procedure TForm1.Button1Click(Sender: TObject);
Var temp1,temp2,i,j,k:integer;
begin
If Opendialog1.Execute then
 Begin
 AssignFile(dumpfile,Opendialog1.FileName);
 FileMode := fmOpenRead;
 Reset(dumpFile);
 i:=0;
 while not eof(dumpfile) do
     begin
     blockread(dumpfile,HexBuffer[UserLogoIndex+i],filesize(dumpfile));
     i:=i+1;
     end;
     closefile(dumpFile);

drawgrid1.Canvas.Pen.Width:=4;
drawgrid1.Canvas.Pen.Color:=clblack;
drawgrid2.Canvas.Pen.Width:=4;
drawgrid2.Canvas.Pen.Color:=clblack;
drawgrid3.Canvas.Pen.Width:=4;
drawgrid3.Canvas.Pen.Color:=clblack;
drawgrid4.Canvas.Pen.Width:=4;
drawgrid4.Canvas.Pen.Color:=clblack;
drawgrid5.Canvas.Pen.Width:=4;
drawgrid5.Canvas.Pen.Color:=clblack;
drawgrid6.Canvas.Pen.Width:=4;
drawgrid6.Canvas.Pen.Color:=clblack;

for k:=0 to 5 do {char 1 - 6}
for j:=0 to 7 do {CGUL}
begin
 temp1:= HexBuffer[UserLogoIndex+j+k*10];
  for i:=0 to 4 do  {row}
  begin
  temp2:= round(power(2,4-i));
  if (temp1 and temp2) =  temp2 then
   case k of
   0:drawgrid1.Canvas.Rectangle(i*10+2,j*10+2,i*10+8,j*10+8);
   1:drawgrid2.Canvas.Rectangle(i*10+2,j*10+2,i*10+8,j*10+8);
   2:drawgrid3.Canvas.Rectangle(i*10+2,j*10+2,i*10+8,j*10+8);
   3:drawgrid4.Canvas.Rectangle(i*10+2,j*10+2,i*10+8,j*10+8);
   4:drawgrid5.Canvas.Rectangle(i*10+2,j*10+2,i*10+8,j*10+8);
   5:drawgrid6.Canvas.Rectangle(i*10+2,j*10+2,i*10+8,j*10+8);
   end;{case}
   end;{for i}
end;{for j}
logocodeshow;
end;
End;

procedure TForm1.Button2Click(Sender: TObject);
begin
If SaveDialog1.Execute then
 begin
  AssignFile(dumpFile, savedialog1.FileName);
   ReWrite(dumpFile);
   Blockwrite(dumpFile,HexBuffer[UserLogoIndex],60);
   closefile(dumpFile);
  end;
end;

End. {End Program}
