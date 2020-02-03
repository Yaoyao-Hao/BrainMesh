function [V,F3,F4]=loadawobj(modelname,opts)
% LOADAWOBJ Load a Wavefront/Alias obj style model.
%  [v,f3,f4]=LOADAWOBJ(modelname) returns three matrices, a
%    vertices matrix, and two matrices defining 3 edge and 4 edge polygons
%  s=LOADAWOBJ(modelname) returns a structure with additional information.
% The only options at present is 'v' to give more verbose output while loading.
% Data in the materials file (.mtl) is handled via loadawmtl.
% see demoloadawobj
%
% When no outputs are given LOADAWOBJ will draw the object.
% When three outputs are given then 
% The program does not handle faces with more than 4 vertices, nor generalised
% specifications such as nurbs.  
%
% s=LOADAWOBJ(modelname) gives a structure
%  version
%  vertices
%  f3 (triangles)
%  f4 (quadrilaterals)
%  groups
%  g3 faces per group
%  g4 faces per group
%  Vn3 Vertex normals indices for f3
%  Vn4 Vertex normals indices for f4
%  Vertex normals (if option is given)
%  Vertex textures (if option is given)
%
% Examples:
%   loadawobj('name.obj') will load and display name.obj
%   S=LOADAWOBJ('name.obj') will load obj into S
%   patch('Vertices',S.v','Faces',S.f3','FaceColor','g');
%
% There is still a chance that obj files will not load. I
% would be grateful for any reports and examples of those that fail.
% See also LOADAWMTL.m DEMOLOADAWOBJ.m
% and Anders Sandberg's
% vertface2obj.m and saveobjmesh.m
%
% W.S. Harwin, University Reading, 2006,2010,2015-6.
% Matlab BSD license
% thanks also to Doug Hackett
%

version=0.32; % add 1 to get the matlab version
if nargin <1 
  if nargout ==1 
      V.version=version;
  else
      warning('need to specify the name of valid obj model as an input.'); 
  end  
  return
end

%options
vbose=0;

% process options (a great deal to process one option!)
if nargin>1
    if isa(opts,'char')
        for jj=opts
            if jj =='v';
                vbose=1;
            end
        end
    end
    if isa(opts,'struct')
        fields = fieldnames(opts);
        for i = 1:numel(fields)
            if fields{i}=='v';
                vbose=opts.v;
            end
        end
    end
end


fid = fopen(modelname,'r');
if (fid<0)
  error(['can not open file: ' modelname]);
  return ;
end

vnum=1;
f3num=1; % triangle (f3) faces so far
f4num=1; % quad (f4) faces so far
f5num=1; % quad (f4) faces so far
f6num=1; % quad (f4) faces so far
vtnum=1; % vertex textures so far
vnnum=1; % vertex normals so far
fline=0; % line number in the obj file
usemtlnum=1;
gnum=1;  % groups so far
unface=[0 0 1 1]; % true if a warning message has been given
L1={}; % An array for lines (could handle faces via a cell array
       % but would not make sense until Mathworks update the patch command

% Vtmp=[]; % set to null so that it can be assigned in the structure
%mat3num=1;
%mat4num=1;
%mtllibnum=1;
%g3num=1; %
%g4num=1;


% Line by line passing of the obj file

while ~feof(fid)
  Ln=fgets(fid);
  fline=fline+1;
  Ln(Ln==10)=[];
  Ln(Ln==13)=[];
  
  if length(Ln)>0 && Ln(end)== '\'
      % disp(sprintf('continuation line %s\n',Ln(50:end)))
      Ln(end)=' ';
      Ln=[Ln fgets(fid)]; % currently only one continuation allowed
      fline=fline+1;
  end
  Ln=removespace(Ln);
  % the following is more elegant but appears to be slower.
  %Ln=strtrim(Ln); % trim space from front and back of string
  %Ln=regexprep(Ln, '\s+', ' '); % trim space in the middle of the string

  l=length(Ln);
  if l==0  % isempty(s) ; 
%    disp(['empty' Ln]);
    continue
  end
  objtype=sscanf(Ln,'%s',1);
  if objtype(1)=='#';objtype='#';end % yet another work around poor obj file structures
  % 
  switch objtype
    case '#' % Comment
      if vbose>0 disp(Ln);end
    case 'v' % Vertex
      v=sscanf(Ln(2:end),'%f');
      Vtmp(:,vnum)=v;
      vnum=vnum+1;
    case 'vt'	% Texture vertex
      vtxtr=sscanf(Ln(3:end),'%f');
      Vtexture(:,vtnum)=vtxtr;
      vtnum=vtnum+1;
    case 'vn' % Vertex normals
      vnorms=sscanf(Ln(3:end),'%f');
      Vnorms(:,vnnum)=vnorms;
      vnnum=vnnum+1;
    case 'g' % sub mesh
      if vbose > 0 ; disp(Ln);end
      %g3num=[g3num f3num];
      %g4num=[g4num f4num];
      g{gnum}=Ln(3:end);
      gnum=gnum+1;
    case 'mtllib' % material library: Currently only allow one material library
        disp(Ln);
        if exist('mtllib','var')
            warning(sprintf('mtllib already set to %s and will be overwritten with %s\n',mtllib,Ln(8:end)))
        end
        mtllib=Ln(8:end);
    case 'usemtl' % use this material name
      if vbose > 0 ; disp(sprintf('%s f3num=%f',Ln,f3num));end
      usemtl(usemtlnum)={Ln(8:end)};
      usemtlnum=usemtlnum+1;
    case 'l' % Line
      l1=sscanf(Ln(3:end),'%f');
      L1=[L1 l1];
%
% 's' Sets the smoothing group for the elements that follow it
%
    case 's' % smooth shading across polygons
      if vbose > 0 ; disp(sprintf('%s f3num=%f',Ln,f3num));end
    case 'o' % user defined polygon and free form geometry statement
        if vbose > 0 ; disp(sprintf('usr def= %s\n',Ln));end
%% Faces
% If an obj does not fully load then it is likely to be because it has
% polygons with more than 4 faces. To rectify add a case to the
% following.  The code needs to identify the number of vertices in the
% face (nvrts), the number of slashes in the line (nslash) and if any
% of these are double slashes (dblslash)
%
    case 'f' % faces
      nvrts=length(findstr(Ln,' ')); % spaces as a predictor of n vertices
      slashpat=findstr(Ln,'/');
      nslash=length(slashpat);
      slashpv=nslash/nvrts; % slashes per vertex group
      if slashpv ==2
          %disp(sprintf('|%s|',Ln));
          dbls=slashpat(2:2:end)-slashpat(1:2:end);
      else
          dbls=0;
      end
      % dbls will now be either 0 - no slashes, or a vector where a
      % each element is the distance between slash pairs
      Ln=Ln(3:end); % get rid of the f
      if slashpv==0 % f 1 2 3
          data1=sscanf(Ln,'%f');
      elseif slashpv==1 % f v/tc
          data1=sscanf(Ln,'%f/%f');
      elseif all(dbls==1) % v//n
          data1=sscanf(Ln,'%f//%f');
      elseif all(dbls>1) % f v/tc/n
          data1=sscanf(Ln,'%f/%f/%f');
      else % assuming there are no cases with 3 or more slash characters per vertex group
          warning(sprintf('Inconsistant faces record in line %d',fline))
          data1=ones(1,72*3); %dummy record
      end
      switch nvrts % The following is face specific. To add polygons with more faces add another case
                   % condition. The code is intended to be easy to modify rather than efficient!
        case 3
          if slashpv==0 % f 1 2 3
              F3(:,f3num)=data1;
          end
          if slashpv==1 % f v/tc
              F3(:,f3num)=data1([1 3 5]);
              Tc3(:,f3num)=data1([2 4 6]);
          end
          if  all(dbls==1) % v//n
              F3(:,f3num)=data1([1 3 5]);
              Vn3(:,f3num)=data1([2 4 6]);
          end
          if  all(dbls>1) % f v/tc/n
              F3(:,f3num)=data1([1 4 7]);
              Tc3(:,f3num)=data1([2 5 8]);
              Vn3(:,f3num)=data1([3 6 9]);
          end
          umat3(f3num)=usemtlnum;
          G3(f3num)=gnum;
          f3num=f3num+1;
        case 4
          if slashpv==0 % f 1 2 3
              F4(:,f4num)=data1;
          end
          if slashpv==1 % f v/tc
              F4(:,f4num)=data1([1 3 5 7]);
              Tc4(:,f4num)=data1([2 4 6 8]);
          end
          if  all(dbls==1) % v//n
              F4(:,f4num)=data1([1 3 5 7]);
              Vn4(:,f4num)=data1([2 4 6 8]);
          end
          if  all(dbls>1) % f v/tc/n
              F4(:,f4num)=data1([1 4 7 10]);
              Tc4(:,f4num)=data1([2 5 8 11]);
              Vn4(:,f4num)=data1([3 6 9 12]);
          end
          umat4(f4num)=usemtlnum;
          G4(f4num)=gnum;
          f4num=f4num+1;
        case 5
          if slashpv==0 % f 1 2 3
              F5(:,f5num)=data1;
          end
          if slashpv==1 % f v/tc
              F5(:,f5num)=data1([1 3 5 7 9]);
              Tc5(:,f5num)=data1([2 4 6 8 10]);
          end
          if  all(dbls==1) % v//n
              F5(:,f5num)=data1([1 3 5 7 9]);
              Vn5(:,f5num)=data1([2 4 6 8 10]);
          end
          if  all(dbls>1) % f v/tc/n
              F5(:,f5num)=data1([1 4 7 10 13]);
              Tc5(:,f5num)=data1([2 5 8 11 14]);
              Vn5(:,f5num)=data1([3 6 9 12 15]);
          end
          umat5(f5num)=usemtlnum;
          G5(f5num)=gnum;
          f5num=f5num+1;
        case 6
          if slashpv==0 % f 1 2 3
              F6(:,f6num)=data1;
          end
          if slashpv==1 % f v/tc
              F6(:,f6num)=data1([1 3 5 7 9 11]);
              Tc6(:,f6num)=data1([2 4 6 8 10 12]);
          end
          if  all(dbls==1) % v//n
              F6(:,f6num)=data1([1 3 5 7 9 11]);
              Vn6(:,f6num)=data1([2 4 6 8 10 12]);
          end
          if  all(dbls>1) % f v/tc/n
              F6(:,f6num)=data1([1 4 7 10 13 16]);
              Tc6(:,f6num)=data1([2 5 8 11 14 17]);
              Vn6(:,f6num)=data1([3 6 9 12 15 18]);
          end
          umat6(f6num)=usemtlnum;
          G6(f6num)=gnum;
          f6num=f6num+1;
        otherwise % nvrts
          if length(unface)<nvrts;unface(nvrts)=0;end % only give the warning once
          if unface(nvrts)==0
              unface(nvrts)=1;
              warning(sprintf('Cannot handle polygons with %d faces. Please edit loadawobj to include this case: %s',nvrts, Ln));
          end
      end
    otherwise % objtype
      disp(['unprocessed:' Ln ':']); % see what has not been processed
    end % switch objType  
end

fclose(fid);



% plot if no output arguments are given
if nargout ==0
  if exist('L1','var')
      %for jj=1:length(L1);D=L1(:,jj);line(D(1,:),D(2,:),D(3,:));end
      for jj=1:length(L1);
          line(Vtmp(1,cell2mat(L1(jj))),Vtmp(2,cell2mat(L1(jj))),Vtmp(3,cell2mat(L1(jj))));
      end
  end
  if exist('F3','var') 
    patch('Vertices',Vtmp','Faces',F3','FaceColor','g');
  end
  if exist('F4','var')
    patch('Vertices',Vtmp','Faces',F4','FaceColor','b');
  end
  if exist('F5','var')
    patch('Vertices',Vtmp','Faces',F5','FaceColor','r');
  end
  if exist('F6','var')
    patch('Vertices',Vtmp','Faces',F6','FaceColor','c');
  end
  axis('equal')
  clear Vtmp F3 F4
end

if nargout >=2 
  V=Vtmp;
  if ~ exist('F3','var') 
    warning('No 3 element faces')
    F3=[];
  end
  if nargout ==3
    if ~ exist('F4','var') 
      warning('No 4 element faces')
      F4=[];
    end
  end
end

if nargout ==1 
  V.version=version;
  if exist('Vtmp','var') && length(Vtmp)>=1
      V.v=Vtmp;
  else
      warning('no vertices found');
  end
  if exist('F3','var')
      V.f3=F3;  end
  if exist('F4','var')
    V.f4=F4;  
  end
  if exist('F5','var')
    V.f5=F5;  
  end
  if exist('F6','var')
    V.f6=F6;  
  end
  if exist('g','var') && gnum>0
      V.g=g;
  end
  if exist('G3','var');V.g3=G3;end
  if exist('G4','var');V.g4=G4;end
  %  V.g4=[g4num f4num];

  if length(L1)>0
      V.l=L1;end
  
  if exist('umat3','var') && ~all(umat3==1)
      V.umat3=umat3;end
  if exist('umat4','var') && ~all(umat4==1)
      V.umat4=umat4;end
  if exist('umat5','var') && ~all(umat5==1)
      V.umat5=umat5;end
  if exist('umat6','var') && ~all(umat6==1)
      V.umat6=umat6;end
  if exist('Vn3','var');V.vn3=Vn3;  end
  if exist('Vn4','var');V.vn4=Vn4;  end
  if exist('Tc3','var');V.tc3=Tc3;  end
  if exist('Tc4','var');V.tc4=Tc4;  end
  if exist('Vnorms','var');V.vn=Vnorms;  end
  if exist('Vtexture','var');V.vt=Vtexture;  end
  if exist('mtllib','var');V.mtllib=mtllib;  end
  if exist('usemtl','var');V.usemtl=usemtl;  end
end


function Record=removespace(Record)
% A not an elegant way to remove
% surplus space
Record=strtrim(Record);
Record=strrep(Record,'       ',' '); % 8-2 .. 12-6  
Record=strrep(Record,'    ',' '); % 5-2 6-3 4-1
Record=strrep(Record,'  ',' '); % 3-2 2-1
Record=strrep(Record,'  ',' '); 
%Record=strrep(Record,char([13 10]),''); % remove cr/lf 
%Record=strrep(Record,char([10]),''); % remove lf 
