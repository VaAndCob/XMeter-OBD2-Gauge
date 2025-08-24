////////////////////////////////////////
//  Inpout32.dll ported to Delphi 6   //
//                                    //
// by Avram,                          //
// avramyu@yahoo.com                  //
////////////////////////////////////////

unit Inpout32;

interface
  procedure Out32(PortAddress, Data: Word); stdcall;
  function Inp32(PortAddress: Word): Word; stdcall;

implementation
  procedure Out32(PortAddress, Data: Word); external 'inpout32.dll';
  function Inp32(PortAddress: Word): Word; external 'inpout32.dll';


end.
 