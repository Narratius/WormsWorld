unit wwTypes;
{ ������� ���� ���� ��������  }

interface

type
 TwwDirection = (dtNone, dtStop, dtLeft, dtUp, dtRight, dtDown);
 TwwDirections = set of TwwDirection;
 TwwEntity = (weLive, weNotLive, weThink);
 TwwEntities = set of TwwEntity;
 TCurve = (ctNone, ctUp, ctDown, ctLeft, ctRight,
           ctLeftUp, ctLeftDown, ctRightUp, ctRightDown);
 TwwFavoriteType = (ftVertical, ftHorizontal);


const
  { ������ ���������� ������� }
  ws_NoBody = 0; // ������ ������
  ws_BodyV  = 1; // ������������ ����
  ws_BodyH  = 2; // �������������� ����
  ws_HeadD  = 3; // ������ ����
  ws_HeadL  = 4; // ������ ������
  ws_HeadR  = 5; // ������ �����
  ws_HeadU  = 6; // ������ �����
  ws_RotD   = 7; // ������� ����� ����
  ws_RotL   = 8; // ������� ����� �������
  ws_RotUL  = 9; // ������� ����� �����
  ws_RotUR  = 10; // ������� ������ �������
  ws_TailD  = 11; // ����� ������
  ws_TailL  = 12; // ����� �����
  ws_TailR  = 13; // ����� ������
  ws_TailU  = 14; // ����� �����
  ws_Target = 15; // ����

const
  weAny = [weLive, weNotLive];

const
  MoveDirs = [dtLeft, dtUp, dtRight, dtDown];
  
implementation


end.
