classdef BrainMesh < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        BrainMeshUIFigure            matlab.ui.Figure
        Tree                         matlab.ui.container.Tree
        addButton                    matlab.ui.control.Button
        UITable                      matlab.ui.control.Table
        DeleteAllButton              matlab.ui.control.Button
        DeleteSelRowButton           matlab.ui.control.Button
        LoadyourpointsButton         matlab.ui.control.Button
        LoadyoursliceimageButton     matlab.ui.control.Button
        Loadyour3DstructureButton    matlab.ui.control.Button
        StartrenderingButton         matlab.ui.control.Button
        STEP13SelectbrainstructuresandaddtotherightTableLabel  matlab.ui.control.Label
        STEP23ChoosecoloralphaandleftrightforeachbrainstructureLabel  matlab.ui.control.Label
        STEP33Renderselected3DbrainstructuresinanewwindowLabel  matlab.ui.control.Label
        OptionalLabel                matlab.ui.control.Label
        objormatwithvFfieldLabel     matlab.ui.control.Label
        matnx3coordinatesLabel       matlab.ui.control.Label
        imagealignedtoCCFLabel       matlab.ui.control.Label
        NoteTextArea                 matlab.ui.control.TextArea
        ExportButton                 matlab.ui.control.Button
        ImportButton                 matlab.ui.control.Button
        DownloadallstructuresButton  matlab.ui.control.Button
        structuresintotalLabel       matlab.ui.control.Label
    end

    
    properties (Access = public)
        all_structures      % store all the allen structures info
        Allen_obj_file_list % all the Allen brain structures (840) with corresponding obj file
        selected_cell       % selected cell index of the UITable
        mid_point = 570     % 1140/2
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, var)
            % Change to current folder
            if(~isdeployed)
                cd(fileparts(which('BrainMesh.m')));
                addpath(fileparts(which('BrainMesh.m')));
                addpath(".\functions\");
            end
            
            wf = waitbar(0,'Loading data...');
            
            % init Tree
            s = load('.\Data\structureTreeTable.mat'); % 2-id; 10-parent id; 4 - full name; 11 - order
            app.all_structures = s.structureTreeTable;
            
            % load structures list with avaiable obj_files
            s = load(".\Data\Allen_obj_file_list.mat");
            app.Allen_obj_file_list = s.Allen_obj_file_list;
            
            waitbar(0.1,wf,'Loading data...');
            
            node_handles = []; node_handles_id = [];
            node_handle = uitreenode(app.Tree,'Text',app.all_structures{1,4}{1},'NodeData',app.all_structures{1,1}+1); %
            node_handles = [node_handles node_handle];
            node_handles_id = [node_handles_id app.all_structures{1,2}];
            n_structure = 1;
            for i = 2:size(app.all_structures,1)
                if any(app.Allen_obj_file_list == app.all_structures{i,2})
                    node_handle = uitreenode(node_handles(node_handles_id == app.all_structures{i,10}),'Text',[app.all_structures{i,5}{1}, ' ', app.all_structures{i,4}{1}],'NodeData',app.all_structures{i,1}+1);
                    node_handles = [node_handles node_handle];
                    node_handles_id = [node_handles_id app.all_structures{i,2}];
                    n_structure = n_structure + 1;
                end
                if rem(i,500) == 0
                    waitbar(0.1+0.8*i/size(app.all_structures,1),wf,'Initializing tree structure...');
                end
            end
                        
            for i = 1:723 % numel(node_handles) before fiber track
                if app.all_structures{node_handles(i).NodeData,11} < 4
                    expand(node_handles(i));
                end
            end
            app.structuresintotalLabel.Text = [num2str(n_structure) ' structures loaded'];
            
            waitbar(0.9,wf,'Finishing...');
            
            % init Table
            app.UITable.Data = {1,'root',num2str([0.80 0.80 0.80],'%1.2f '),0.2,true,true};
            s = uistyle('BackgroundColor',[0.8 0.8 0.8]);
            addStyle(app.UITable,s,'cell',[1,3]);
            
            close(wf);
        end

        % Button pushed function: StartrenderingButton
        function StartrenderingButtonPushed(app, event)
            waitf = uiprogressdlg(app.BrainMeshUIFigure,'Title','Please Wait','Message','Loading data...');
            
            f = figure('name','BrainMesh->Rendering', 'numbertitle','off', 'ToolBar','none','Visible',"off");
            hold("on");

            if(~isdeployed)
                cd(fileparts(which('BrainMesh.m')));
            end
            
            for i = 1:size(app.UITable.Data,1)
                waitf.Value = 0.8*i/size(app.UITable.Data,1); 
                waitf.Message = ['Loading and Rendering ' num2str(i) '/' num2str(size(app.UITable.Data,1)) ' structure...'];
                if ~ischar(app.UITable.Data{i,1}) % added Allen obj files
                    
                    if app.UITable.Data{i,5} || app.UITable.Data{i,6}
                        
                        % check current obj files in the folder
                        obj_files = dir('.\Data\Allen_obj_files\*.obj');
                        D = struct2cell(obj_files);
                        obj_files = D(1,:)';
                        curr_obj_file_list = zeros(numel(obj_files),1);
                        for i_obj = 1:numel(obj_files)
                            curr_obj_file_list(i_obj) = str2double(obj_files{i}(1:end-4));
                        end
                        
                        if ~any(app.all_structures{app.UITable.Data{i,1},2} == curr_obj_file_list) % not downloaded yet
                            websave(['.\Data\Allen_obj_files\' num2str(app.all_structures{app.UITable.Data{i,1},2}) '.obj'],...
                                ['http://download.alleninstitute.org/informatics-archive/current-release/mouse_ccf/annotation/ccf_2017/structure_meshes/' num2str(app.all_structures{app.UITable.Data{i,1},2}) '.obj']);
                        end
                        
                        [v,F]=loadawobj(['.\Data\Allen_obj_files\',num2str(app.all_structures{app.UITable.Data{i,1},2}),'.obj']);
                        v = v/10;
                        if app.UITable.Data{i,5}
                            if ~app.UITable.Data{i,6} % left
                                index_v = find(v(3,:)>app.mid_point);
                                
                                index_F = [];
                                for j = 1:size(F,2)
                                    if any(ismember(F(:,j),index_v))
                                        index_F = [index_F j];
                                    end
                                end
                                F(:,index_F) = [];
                            end
                        else % right
                            index_v = find(v(3,:)<app.mid_point);
                            
                            index_F = [];
                            for j = 1:size(F,2)
                                if any(ismember(F(:,j),index_v))
                                    index_F = [index_F j];
                                end
                            end
                            F(:,index_F) = [];
                        end
                        patch('Vertices',v','Faces',F','EdgeColor','none','FaceColor',str2num(app.UITable.Data{i,3}),'FaceAlpha',app.UITable.Data{i,4});
                    end
                    
                else % user points/slice/3d-strutures
                    if strcmp(app.UITable.Data{i,1},'u_pts')
                        pts = load(app.UITable.Data{i,5});
                        pts = eval(['pts.' app.UITable.Data{i,2}]);
                        plot3(pts(:,1),pts(:,2),pts(:,3),'.','MarkerSize',app.UITable.Data{i,6},"Color",str2num(app.UITable.Data{i,3}));
                    elseif strcmp(app.UITable.Data{i,1},'u_slice')
                        I = imread(app.UITable.Data{i,5});
                        [row,col] = size(I);
                        [X, Y] = meshgrid(1:row, fliplr(1:col));
                        if row == 800 && col == 1140
                            surf(app.UITable.Data{i,6}*ones(size(I)), X', Y', I,'EdgeColor','none','facealpha',app.UITable.Data{i,4}); % Coronal section at level app.UITable.Data{i,6} (1-1320)
                        elseif col == 800 && row == 1140
                            I = I';
                            surf(app.UITable.Data{i,6}*ones(size(I)), X', Y', I,'EdgeColor','none','facealpha',app.UITable.Data{i,4}); % Coronal section at level app.UITable.Data{i,6} (1-1320)
                        elseif row == 800 && col == 1320
                            surf(X', Y', app.UITable.Data{i,6}*ones(size(I)), I,'EdgeColor','none','facealpha',app.UITable.Data{i,4}); % segital
                        elseif col == 800 && row == 1320
                            I = I';
                            surf(X', Y', app.UITable.Data{i,6}*ones(size(I)), I,'EdgeColor','none','facealpha',app.UITable.Data{i,4}); % segital
                        elseif row == 1140 && col == 1320
                            surf(X', app.UITable.Data{i,6}*ones(size(I)), Y',  I,'EdgeColor','none','facealpha',app.UITable.Data{i,4}); % horizontal
                        elseif col == 1140 && row == 1320
                            I = I';
                            surf(X', app.UITable.Data{i,6}*ones(size(I)), Y',  I,'EdgeColor','none','facealpha',app.UITable.Data{i,4}); % horizontal
                        end
                        colormap(app.UITable.Data{i,3});
                    elseif strcmp(app.UITable.Data{i,1},'u_3dmat')
                        u_structure = load(app.UITable.Data{i,5});
                        u_structure = eval(['u_structure.' app.UITable.Data{i,2}]);
                        patch('Vertices',u_structure.v','Faces',u_structure.F','EdgeColor','none','FaceColor',str2num(app.UITable.Data{i,3}),'FaceAlpha',app.UITable.Data{i,4});
                    elseif strcmp(app.UITable.Data{i,1},'u_3dobj')
                        [v,F]=loadawobj(app.UITable.Data{i,5});
                        patch('Vertices',v','Faces',F','EdgeColor','none','FaceColor',str2num(app.UITable.Data{i,3}),'FaceAlpha',app.UITable.Data{i,4});
                    end
                end
            end
            
            waitf.Value = .90; waitf.Message = 'Finishing...';
            
            view(-5,-25); camroll(10);
            axis('equal'); axis('off'); axis('tight'); axis('vis3d');
            light('Position',[-7000 -10000 -5000]);
            snapnow
            ctb = cameratoolbar(f,'show');
            uipushtool(ctb,'CData',double(imread('.\Data\icons\icon_x.png'))/255,'Separator','on','ClickedCallback',{@spin_callback,'x'}, ...
                "HandleVisibility",'on','Tooltip','Spin along x-axis');
            uipushtool(ctb,'CData',double(imread('.\Data\icons\icon_y.png'))/255,'Separator','off','ClickedCallback',{@spin_callback,'y'}, ...
                "HandleVisibility",'on','Tooltip','Spin along y-axis');
            uipushtool(ctb,'CData',double(imread('.\Data\icons\icon_z.png'))/255,'Separator','off','ClickedCallback',{@spin_callback,'z'}, ...
                "HandleVisibility",'on','Tooltip','Spin along z-axis');
            uipushtool(ctb,'CData',double(imread('.\Data\icons\icon_video.png'))/255,'Separator','on','ClickedCallback',@video_callback, ...
                "HandleVisibility",'on','Tooltip','Export spin video');
            
            close(waitf);
            f.Visible = 'on';
            
            function spin_callback(~,~,spin_axis)
                for k = 1:36
                    camorbit(10,0,'data',spin_axis)
                    drawnow
                    pause(0.05);
                end
            end
            
            function video_callback(~,~)
                answer = inputdlg({'How many cycles?','Duration for each cycle (sec):','Spin axis (x, y, or z):','Frame rate:','File name (*.avi or *.mp4):'},...
                    'Video parameters', [1 50; 1 50; 1 50; 1 50; 1 50],{'1','3','y','15',['spin-' datestr(now,'yyyy-mmm-dd-HH-MM-SS') '.avi']});
                if isempty(answer)
                    return;
                else
                    videoObj=VideoWriter(['.\output\', answer{5}]);
                    videoObj.FrameRate = str2double(answer{4});
                    try
                        open(videoObj);
                        theta = 360/(str2double(answer{2})*str2double(answer{4})); % 360/(cycle_dur*FrameRate)
                        for k = 1:round(str2double(answer{1})*360/theta)
                            camorbit(theta,0,'data',answer{3})
                            drawnow;
                            writeVideo(videoObj,getframe(gcf));
                            % pause(0.05);
                        end
                        close(videoObj);
                        msgbox(['Video file (' answer{5} ') recorded successfully (folder: .\output\).']);
                    catch
                        close(videoObj);
                        errordlg('Write video file failed.');
                    end
                end
            end
            
        end

        % Close request function: BrainMeshUIFigure
        function BrainMeshUIFigureCloseRequest(app, event)
            selection = questdlg('Are you sure you want to close this window?',...
                'Confirmation',...
                'Yes','No','Yes');
            switch selection
                case 'Yes'
                    delete(app)
                case 'No'
                    return
            end
        end

        % Button pushed function: addButton
        function addButtonPushed(app, event)
            % read slected items in tree
            selected_nodes = app.Tree.SelectedNodes;
            % read content in table
            index_in_table = [];
            if ~isempty(app.UITable.Data)
                for i = 1:size(app.UITable.Data,1)
                    if ~ischar(app.UITable.Data{i,1})
                        index_in_table = [index_in_table app.UITable.Data{i,1}];
                    end
                end
            end
            % add to the table
            for i = 1:numel(selected_nodes)
                index = selected_nodes(i).NodeData;
                if index == 1 % root
                    app.UITable.Data = [app.UITable.Data; {index,app.all_structures{index,5}{1},num2str(hex2rgb(app.all_structures{index,15}),'%1.2f '),0.2,true,true}];
                else
                    app.UITable.Data = [app.UITable.Data; {index,app.all_structures{index,5}{1},num2str(hex2rgb(app.all_structures{index,15}),'%1.2f '),0.8,true,true}];
                end
                s = uistyle('BackgroundColor',hex2rgb(table2array(app.all_structures(index,15))));
                addStyle(app.UITable,s,'cell',[size(app.UITable.Data,1),3]);
                if any(index_in_table == index)
                    warndlg(['structure ' app.all_structures{index,5}{1} ' is already in the Table.']);
                end
            end
        end

        % Button pushed function: DeleteAllButton
        function DeleteAllButtonPushed(app, event)
            app.UITable.Data = [];
        end

        % Button pushed function: DeleteSelRowButton
        function DeleteSelRowButtonPushed(app, event)
            app.UITable.Data(app.selected_cell(:,1),:) = []; % delete rows
            % correct color
            if ~isempty(app.UITable.Data)
                for i = 1:size(app.UITable.Data,1)
                    if ~ischar(app.UITable.Data{i,1}) % added Allen obj files
                        s = uistyle('BackgroundColor',str2num(app.UITable.Data{i,3}));
                        addStyle(app.UITable,s,'cell',[i,3]);
                    elseif strcmp(app.UITable.Data{i,1},'u_pts') || strcmp(app.UITable.Data{i,1},'u_3dobj') || strcmp(app.UITable.Data{i,1},'u_3dmat')
                        s = uistyle('BackgroundColor',str2num(app.UITable.Data{i,3}));
                        addStyle(app.UITable,s,'cell',[i,3]);
                    elseif strcmp(app.UITable.Data{i,1},'u_slice')
                        s = uistyle('BackgroundColor',[0.93 0.93 0.93]);
                        addStyle(app.UITable,s,'cell',[i,3]);
                    end
                end
            end
        end

        % Cell selection callback: UITable
        function UITableCellSelection(app, event)
            app.selected_cell = event.Indices;
            if size(app.selected_cell,1) == 1 && app.selected_cell(1,2) == 3
                if ischar(app.UITable.Data{app.selected_cell(1,1),1}) && strcmp(app.UITable.Data{app.selected_cell(1,1),1},'u_slice')
                    answer = inputdlg('Enter a colormap (gray, jet, hsv, etc.): ','Chose a colormap');
                    if isempty(answer) || numel(answer)>1
                        return;
                    else
                        answer = answer{1};
                    end
                    app.UITable.Data{app.selected_cell(1,1),3} = answer;
                else
                    % color selection
                    c = uisetcolor('Select a color');
                    if numel(c) ~= 1
                        s = uistyle('BackgroundColor',c);
                        addStyle(app.UITable,s,'cell',app.selected_cell);
                        app.UITable.Data{app.selected_cell(1,1),3} = num2str(c,'%1.2f ');
                    end
                end
            end
            
        end

        % Button pushed function: LoadyourpointsButton
        function LoadyourpointsButtonPushed(app, event)
            [file,path] = uigetfile({'*.mat','MAT-files (*.mat)'; '*.*',  'All Files (*.*)'}, 'Select a File');
            if isequal(file,0)
                % disp('User selected Cancel')
                return;
            else
                % disp(['User selected ', fullfile(path, file),' and filter index: ', num2str(indx)])
                pts = load(fullfile(path, file));
                % assert nx3
                if size(eval(['pts.' file(1:end-4)]),2)~=3
                    errordlg('loaded mat file must be nx3');
                    return;
                end
            end
            % chose marker type (omit)
            % add to table
            random_color = rand(1,3);
            app.UITable.Data = [app.UITable.Data; {'u_pts',file(1:end-4),num2str(random_color,'%1.2f '),'NA',fullfile(path, file),15}];
            s = uistyle('BackgroundColor',random_color);
            addStyle(app.UITable,s,'cell',[size(app.UITable.Data,1),3]);
        end

        % Button pushed function: LoadyoursliceimageButton
        function LoadyoursliceimageButtonPushed(app, event)

            [file,path] = uigetfile({'*.*', 'All Files (*.*)'}, 'Select a File');
            if isequal(file,0)
                % disp('User selected Cancel')
                return;
            else
                % disp(['User selected ', fullfile(path, file),' and filter index: ', num2str(indx)])
                I = imread(fullfile(path, file));
                [row,col] = size(I);
                if (row == 800 && col == 1140) || (col == 800 && row == 1140)
                    section = 'coronal';
                    range = '(1-1320)';
                elseif (row == 800 && col == 1320) || (col == 800 && row == 1320)
                    section = 'segital';
                    range = '(1-1140)';
                elseif (row == 1140 && col == 1320) || (col == 1140 && row == 1320)
                    section = 'horizontal';
                    range = '(1-800)';
                else
                    errordlg('loaded image must be 1140x800 (coronal), 1320x800 (segital) or 1320*1140 (horizontal)');
                    return;
                end
                answer = inputdlg(['Enter location for this ', section,' slice ', range ,':'],'Silce Location: ');
                if isempty(answer) || numel(answer)>1
                    return;
                else
                    answer = str2num(answer{1});
                end
            end
            % add to table
            app.UITable.Data = [app.UITable.Data; {'u_slice',file(1:end-4),'gray',0.5,fullfile(path, file),answer}];
            s = uistyle('BackgroundColor',[0.93 0.93 0.93]);
            addStyle(app.UITable,s,'cell',[size(app.UITable.Data,1),3]);
        end

        % Button pushed function: Loadyour3DstructureButton
        function Loadyour3DstructureButtonPushed(app, event)
            [file,path] = uigetfile({'*.mat;*.obj', 'Support Files (*.mat,*.obj)'; '*.*',  'All Files (*.*)'}, 'Select a File');
            if isequal(file,0)
                % disp('User selected Cancel')
                return;
            else
                % disp(['User selected ', fullfile(path, file),' and filter index: ', num2str(indx)])
                if strcmp(file(end-2:end),'mat')
                    u_structure = load(fullfile(path, file));
                    u_structure = eval(['u_structure.' file(1:end-4)]);
                    if ~isfield(u_structure,'v') || ~isfield(u_structure,'F')
                        errordlg('loaded mat file must have v(verticies) and F(Faces) field');
                        return;
                    end
                    index = 'u_3dmat';
                else
                    index = 'u_3dobj';
                end
            end
            % add to table
            random_color = rand(1,3);
            app.UITable.Data = [app.UITable.Data; {index,file(1:end-4),num2str(random_color,'%1.2f '),0.8,fullfile(path, file),''}]; % random color
            s = uistyle('BackgroundColor',random_color);
            addStyle(app.UITable,s,'cell',[size(app.UITable.Data,1),3]);
        end

        % Button pushed function: ImportButton
        function ImportButtonPushed(app, event)
            [file,path] = uigetfile('structure_table_exported.mat');
            if isequal(file,0)
                % disp('User selected Cancel');
                return;
            else
                % disp(['User selected ', fullfile(path,file)]);
                TD = load(fullfile(path,file));
                if size(TD.TableData,2) == 6
                    app.UITable.Data = [app.UITable.Data; TD.TableData];
                    % color
                    for i = 1:size(app.UITable.Data,1)
                        if ~ischar(app.UITable.Data{i,1}) % added Allen obj files
                            s = uistyle('BackgroundColor',str2num(app.UITable.Data{i,3}));
                            addStyle(app.UITable,s,'cell',[i,3]);
                        elseif strcmp(app.UITable.Data{i,1},'u_pts') || strcmp(app.UITable.Data{i,1},'u_3dobj') || strcmp(app.UITable.Data{i,1},'u_3dmat')
                            s = uistyle('BackgroundColor',str2num(app.UITable.Data{i,3}));
                            addStyle(app.UITable,s,'cell',[i,3]);
                        elseif strcmp(app.UITable.Data{i,1},'u_slice')
                            s = uistyle('BackgroundColor',[0.93 0.93 0.93]);
                            addStyle(app.UITable,s,'cell',[i,3]);
                        end
                    end
                else
                    errordlg('mat file must be nx6 Table.');
                    return;
                end
            end
        end

        % Button pushed function: ExportButton
        function ExportButtonPushed(app, event)
            TableData = app.UITable.Data;
            uisave('TableData','structure_table_exported.mat');
        end

        % Button pushed function: DownloadallstructuresButton
        function DownloadallstructuresButtonPushed(app, event)
            selection = questdlg('Are you sure you want to download all 840 Allen brain structures (227 MB) to your computer? This will take a few minutes...',...
                'Confirmation',...
                'Yes','No','Yes');
            switch selection
                case 'Yes'
                    if(~isdeployed)
                        cd(fileparts(which('BrainMesh.m')));
                    end
                    % check current files in the folder
                    obj_files = dir('.\Data\Allen_obj_files\*.obj');
                    D = struct2cell(obj_files);
                    obj_files = D(1,:)';
                    curr_obj_file_list = zeros(numel(obj_files),1);
                    for i = 1:numel(obj_files)
                        curr_obj_file_list(i) = str2double(obj_files{i}(1:end-4));
                    end
                    
                    waitf = uiprogressdlg(app.BrainMeshUIFigure,'Title','Downloading files from Allen Institute','Message','Downloading 1/840 file...');
                    
                    for i_file = 1:numel(app.Allen_obj_file_list)
                        waitf.Value = i_file/numel(app.Allen_obj_file_list);
                        waitf.Message = ['Downloading ' num2str(i_file) '/840 file...'];
                        if ~any(app.Allen_obj_file_list(i_file) == curr_obj_file_list)
                            % only download missing files
                            websave(['.\Data\Allen_obj_files\' num2str(app.Allen_obj_file_list(i_file)) '.obj'],...
                                ['http://download.alleninstitute.org/informatics-archive/current-release/mouse_ccf/annotation/ccf_2017/structure_meshes/' num2str(app.Allen_obj_file_list(i_file)) '.obj']);
                        end
                    end
                    
                    close(waitf);
                    
                    msgbox('All structures (*.obj) downloaded to folder .\Data\Allen_obj_files\');
                case 'No'
                    return;
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create BrainMeshUIFigure and hide until all components are created
            app.BrainMeshUIFigure = uifigure('Visible', 'off');
            app.BrainMeshUIFigure.AutoResizeChildren = 'off';
            app.BrainMeshUIFigure.Position = [10 150 1024 768];
            app.BrainMeshUIFigure.Name = 'BrainMesh';
            app.BrainMeshUIFigure.Resize = 'off';
            app.BrainMeshUIFigure.CloseRequestFcn = createCallbackFcn(app, @BrainMeshUIFigureCloseRequest, true);

            % Create Tree
            app.Tree = uitree(app.BrainMeshUIFigure);
            app.Tree.Multiselect = 'on';
            app.Tree.Position = [50 55 350 663];

            % Create addButton
            app.addButton = uibutton(app.BrainMeshUIFigure, 'push');
            app.addButton.ButtonPushedFcn = createCallbackFcn(app, @addButtonPushed, true);
            app.addButton.Position = [415 490 70 25];
            app.addButton.Text = 'add >>';

            % Create UITable
            app.UITable = uitable(app.BrainMeshUIFigure);
            app.UITable.ColumnName = {'Index'; 'Name'; 'Color (RGB)'; 'Alpha'; 'Left'; 'Right'};
            app.UITable.ColumnWidth = {70, 150, 'auto', 50, 50, 50};
            app.UITable.ColumnEditable = [false false false true true true];
            app.UITable.CellSelectionCallback = createCallbackFcn(app, @UITableCellSelection, true);
            app.UITable.Position = [500 286 500 432];

            % Create DeleteAllButton
            app.DeleteAllButton = uibutton(app.BrainMeshUIFigure, 'push');
            app.DeleteAllButton.ButtonPushedFcn = createCallbackFcn(app, @DeleteAllButtonPushed, true);
            app.DeleteAllButton.Position = [776 254 100 28];
            app.DeleteAllButton.Text = 'Delete All';

            % Create DeleteSelRowButton
            app.DeleteSelRowButton = uibutton(app.BrainMeshUIFigure, 'push');
            app.DeleteSelRowButton.ButtonPushedFcn = createCallbackFcn(app, @DeleteSelRowButtonPushed, true);
            app.DeleteSelRowButton.Position = [900 254 100 28];
            app.DeleteSelRowButton.Text = 'Delete Sel Row';

            % Create LoadyourpointsButton
            app.LoadyourpointsButton = uibutton(app.BrainMeshUIFigure, 'push');
            app.LoadyourpointsButton.ButtonPushedFcn = createCallbackFcn(app, @LoadyourpointsButtonPushed, true);
            app.LoadyourpointsButton.Position = [514 200 147 35];
            app.LoadyourpointsButton.Text = 'Load your point(s)...';

            % Create LoadyoursliceimageButton
            app.LoadyoursliceimageButton = uibutton(app.BrainMeshUIFigure, 'push');
            app.LoadyoursliceimageButton.ButtonPushedFcn = createCallbackFcn(app, @LoadyoursliceimageButtonPushed, true);
            app.LoadyoursliceimageButton.Position = [681 200 147 35];
            app.LoadyoursliceimageButton.Text = 'Load your slice image...';

            % Create Loadyour3DstructureButton
            app.Loadyour3DstructureButton = uibutton(app.BrainMeshUIFigure, 'push');
            app.Loadyour3DstructureButton.ButtonPushedFcn = createCallbackFcn(app, @Loadyour3DstructureButtonPushed, true);
            app.Loadyour3DstructureButton.Position = [846.5 200 148 35];
            app.Loadyour3DstructureButton.Text = 'Load your 3D structure...';

            % Create StartrenderingButton
            app.StartrenderingButton = uibutton(app.BrainMeshUIFigure, 'push');
            app.StartrenderingButton.ButtonPushedFcn = createCallbackFcn(app, @StartrenderingButtonPushed, true);
            app.StartrenderingButton.FontSize = 16;
            app.StartrenderingButton.Position = [824 75 176 52];
            app.StartrenderingButton.Text = 'Start rendering >>>';

            % Create STEP13SelectbrainstructuresandaddtotherightTableLabel
            app.STEP13SelectbrainstructuresandaddtotherightTableLabel = uilabel(app.BrainMeshUIFigure);
            app.STEP13SelectbrainstructuresandaddtotherightTableLabel.FontWeight = 'bold';
            app.STEP13SelectbrainstructuresandaddtotherightTableLabel.FontColor = [0.4667 0.6745 0.1882];
            app.STEP13SelectbrainstructuresandaddtotherightTableLabel.Position = [50 717 356 22];
            app.STEP13SelectbrainstructuresandaddtotherightTableLabel.Text = 'STEP 1/3: Select brain structure(s) and add to the right Table';

            % Create STEP23ChoosecoloralphaandleftrightforeachbrainstructureLabel
            app.STEP23ChoosecoloralphaandleftrightforeachbrainstructureLabel = uilabel(app.BrainMeshUIFigure);
            app.STEP23ChoosecoloralphaandleftrightforeachbrainstructureLabel.FontWeight = 'bold';
            app.STEP23ChoosecoloralphaandleftrightforeachbrainstructureLabel.FontColor = [0.0745 0.6235 1];
            app.STEP23ChoosecoloralphaandleftrightforeachbrainstructureLabel.Position = [500 717 399 22];
            app.STEP23ChoosecoloralphaandleftrightforeachbrainstructureLabel.Text = 'STEP 2/3: Choose color, alpha and left/right for each brain structure';

            % Create STEP33Renderselected3DbrainstructuresinanewwindowLabel
            app.STEP33Renderselected3DbrainstructuresinanewwindowLabel = uilabel(app.BrainMeshUIFigure);
            app.STEP33Renderselected3DbrainstructuresinanewwindowLabel.FontWeight = 'bold';
            app.STEP33Renderselected3DbrainstructuresinanewwindowLabel.FontColor = [1 0.4118 0.1608];
            app.STEP33Renderselected3DbrainstructuresinanewwindowLabel.Position = [627 55 373 22];
            app.STEP33Renderselected3DbrainstructuresinanewwindowLabel.Text = 'STEP 3/3: Render selected 3D brain structure(s) in a new window';

            % Create OptionalLabel
            app.OptionalLabel = uilabel(app.BrainMeshUIFigure);
            app.OptionalLabel.FontAngle = 'italic';
            app.OptionalLabel.FontColor = [0.0745 0.6235 1];
            app.OptionalLabel.Position = [520 234 58 22];
            app.OptionalLabel.Text = '(Optional)';

            % Create objormatwithvFfieldLabel
            app.objormatwithvFfieldLabel = uilabel(app.BrainMeshUIFigure);
            app.objormatwithvFfieldLabel.FontAngle = 'italic';
            app.objormatwithvFfieldLabel.Position = [847 178 156 22];
            app.objormatwithvFfieldLabel.Text = '*.obj or *.mat with v & F field';

            % Create matnx3coordinatesLabel
            app.matnx3coordinatesLabel = uilabel(app.BrainMeshUIFigure);
            app.matnx3coordinatesLabel.FontAngle = 'italic';
            app.matnx3coordinatesLabel.Position = [525 178 125 22];
            app.matnx3coordinatesLabel.Text = '*.mat, nx3 coordinates';

            % Create imagealignedtoCCFLabel
            app.imagealignedtoCCFLabel = uilabel(app.BrainMeshUIFigure);
            app.imagealignedtoCCFLabel.FontAngle = 'italic';
            app.imagealignedtoCCFLabel.Position = [694 179 122 22];
            app.imagealignedtoCCFLabel.Text = 'image aligned to CCF';

            % Create NoteTextArea
            app.NoteTextArea = uitextarea(app.BrainMeshUIFigure);
            app.NoteTextArea.Editable = 'off';
            app.NoteTextArea.BackgroundColor = [0.9412 0.9412 0.9412];
            app.NoteTextArea.Position = [497 128 181 49];
            app.NoteTextArea.Value = {'X: Anterior - Posterior (1-1320)'; 'Y: Dorsal - Ventral       (1- 800)'; 'Z: Left - Right              (1-1140)'};

            % Create ExportButton
            app.ExportButton = uibutton(app.BrainMeshUIFigure, 'push');
            app.ExportButton.ButtonPushedFcn = createCallbackFcn(app, @ExportButtonPushed, true);
            app.ExportButton.Position = [672 257 55 22];
            app.ExportButton.Text = 'Export...';

            % Create ImportButton
            app.ImportButton = uibutton(app.BrainMeshUIFigure, 'push');
            app.ImportButton.ButtonPushedFcn = createCallbackFcn(app, @ImportButtonPushed, true);
            app.ImportButton.Position = [603.5 257 60 22];
            app.ImportButton.Text = 'Import...';

            % Create DownloadallstructuresButton
            app.DownloadallstructuresButton = uibutton(app.BrainMeshUIFigure, 'push');
            app.DownloadallstructuresButton.ButtonPushedFcn = createCallbackFcn(app, @DownloadallstructuresButtonPushed, true);
            app.DownloadallstructuresButton.Position = [74 21 140 30];
            app.DownloadallstructuresButton.Text = 'Download all structures';

            % Create structuresintotalLabel
            app.structuresintotalLabel = uilabel(app.BrainMeshUIFigure);
            app.structuresintotalLabel.HorizontalAlignment = 'right';
            app.structuresintotalLabel.Position = [267 25 116 22];
            app.structuresintotalLabel.Text = 'structures in total';

            % Show the figure after all components are created
            app.BrainMeshUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = BrainMesh(varargin)

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.BrainMeshUIFigure)

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.BrainMeshUIFigure)
        end
    end
end