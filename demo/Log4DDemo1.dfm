object frmLog4DDemo: TfrmLog4DDemo
  Left = 192
  Top = 120
  Width = 656
  Height = 610
  ActiveControl = edtMessage
  Caption = 'Log4D Demo'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -10
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  ShowHint = True
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object splVert: TSplitter
    Left = 284
    Top = 76
    Width = 2
    Height = 507
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 648
    Height = 76
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object Label1: TLabel
      Left = 21
      Top = 7
      Width = 31
      Height = 13
      Alignment = taRightJustify
      Caption = '&Priority'
      FocusControl = cmbPriority
    end
    object Label2: TLabel
      Left = 130
      Top = 7
      Width = 42
      Height = 13
      Alignment = taRightJustify
      Caption = '&Category'
      FocusControl = cmbCategory
    end
    object Label3: TLabel
      Left = 9
      Top = 29
      Width = 43
      Height = 13
      Alignment = taRightJustify
      Caption = '&Message'
      FocusControl = edtMessage
    end
    object edtMessage: TEdit
      Left = 56
      Top = 26
      Width = 205
      Height = 21
      Hint = 'Enter the message to be logged'
      TabOrder = 2
    end
    object btnLog: TButton
      Left = 117
      Top = 49
      Width = 61
      Height = 20
      Hint = 'Log the above message and priority'
      Caption = '&Log'
      Default = True
      TabOrder = 3
      OnClick = btnLogClick
    end
    object cmbCategory: TComboBox
      Left = 176
      Top = 3
      Width = 85
      Height = 21
      Hint = 'Select the category to perform the logging'
      Style = csDropDownList
      ItemHeight = 13
      TabOrder = 1
      Items.Strings = (
        'myapp'
        'myapp.more'
        'myapp.other'
        'alt')
    end
    object grpFilter: TGroupBox
      Left = 272
      Top = 3
      Width = 85
      Height = 66
      Caption = '&Filter'
      TabOrder = 4
      object edtFilter: TEdit
        Left = 33
        Top = 14
        Width = 20
        Height = 21
        Hint = 'Enter a character to filter by'
        MaxLength = 1
        TabOrder = 0
      end
      object btnFilter: TButton
        Left = 11
        Top = 39
        Width = 61
        Height = 20
        Hint = 'Include messages with the above character for category '#39'test'#39
        Caption = 'Fil&ter'
        TabOrder = 1
        OnClick = btnFilterClick
      end
    end
    object grpNDC: TGroupBox
      Left = 366
      Top = 3
      Width = 164
      Height = 66
      Caption = '&NDC'
      TabOrder = 5
      object edtNDC: TEdit
        Left = 16
        Top = 13
        Width = 134
        Height = 21
        Hint = 'Enter context information'
        TabOrder = 0
      end
      object btnPush: TButton
        Left = 15
        Top = 39
        Width = 61
        Height = 20
        Hint = 'Add the context information above to the stack'
        Caption = 'P&ush'
        TabOrder = 1
        OnClick = btnPushClick
      end
      object btnPop: TButton
        Left = 93
        Top = 39
        Width = 61
        Height = 20
        Hint = 'Remove the latest context information from the stack'
        Caption = 'P&op'
        TabOrder = 2
        OnClick = btnPopClick
      end
    end
    object cmbPriority: TComboBox
      Left = 56
      Top = 3
      Width = 63
      Height = 21
      Hint = 'Select the priority of the message'
      Style = csDropDownList
      ItemHeight = 13
      TabOrder = 0
    end
    object btnLoop: TButton
      Left = 548
      Top = 28
      Width = 75
      Height = 20
      Hint = 'Loop through messages and an error'
      Caption = 'Loop to &Error'
      TabOrder = 6
      OnClick = btnLoopClick
    end
  end
  object pnlLeft: TPanel
    Left = 0
    Top = 76
    Width = 284
    Height = 507
    Align = alLeft
    BevelOuter = bvNone
    TabOrder = 1
    object lblMyApp: TLabel
      Left = 0
      Top = 0
      Width = 284
      Height = 13
      Align = alTop
      Caption = ' myapp'
    end
    object splLeft: TSplitter
      Left = 0
      Top = 256
      Width = 284
      Height = 3
      Cursor = crVSplit
      Align = alTop
      OnMoved = splLeftMoved
    end
    object lblMyAppMore: TLabel
      Left = 0
      Top = 259
      Width = 284
      Height = 13
      Align = alTop
      Caption = ' myapp.more'
    end
    object memMyApp: TMemo
      Left = 0
      Top = 13
      Width = 284
      Height = 243
      Hint = 'Output for category '#39'test'#39
      Align = alTop
      ScrollBars = ssVertical
      TabOrder = 0
    end
    object memMyAppMore: TMemo
      Left = 0
      Top = 272
      Width = 284
      Height = 235
      Hint = 'Output for category '#39'test.more'#39
      Align = alClient
      ScrollBars = ssVertical
      TabOrder = 1
    end
  end
  object pnlRight: TPanel
    Left = 286
    Top = 76
    Width = 362
    Height = 507
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 2
    object splRight: TSplitter
      Left = 0
      Top = 256
      Width = 362
      Height = 3
      Cursor = crVSplit
      Align = alTop
      OnMoved = splRightMoved
    end
    object lblMyAppOther: TLabel
      Left = 0
      Top = 0
      Width = 362
      Height = 13
      Align = alTop
      Caption = ' myapp.other'
    end
    object lblAlt: TLabel
      Left = 0
      Top = 259
      Width = 362
      Height = 13
      Align = alTop
      Caption = ' alt'
    end
    object memMyAppOther: TMemo
      Left = 0
      Top = 13
      Width = 362
      Height = 243
      Hint = 'Output for category '#39'test.other'#39
      Align = alTop
      ScrollBars = ssVertical
      TabOrder = 0
    end
    object memAlt: TMemo
      Left = 0
      Top = 272
      Width = 362
      Height = 235
      Hint = 'Output for category '#39'alt'#39
      Align = alClient
      ScrollBars = ssVertical
      TabOrder = 1
    end
  end
end
