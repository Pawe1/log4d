{ Define flags for different Delphi versions }

{$IFDEF VER120}  { Delphi 4 }
{$DEFINE DELPHI4}
{$DEFINE DELPHI4_UP}
{$ENDIF}

{$IFDEF VER130}  { Delphi 5 }
{$DEFINE DELPHI5}
{$DEFINE DELPHI4_UP}
{$DEFINE DELPHI5_UP}
{$ENDIF}

{$IFDEF VER140}  { Delphi 6 }
{$DEFINE DELPHI6}
{$DEFINE DELPHI4_UP}
{$DEFINE DELPHI5_UP}
{$DEFINE DELPHI6_UP}
{$ENDIF}

{$IFDEF VER150}  { Delphi 7 }
{$DEFINE DELPHI7}
{$DEFINE DELPHI4_UP}
{$DEFINE DELPHI5_UP}
{$DEFINE DELPHI6_UP}
{$DEFINE DELPHI7_UP}
{$ENDIF}