function varargout = EpiTools(varargin)
% EPITOOLS MATLAB code for EpiTools.fig
%      EPITOOLS, by itself, creates a new EPITOOLS or raises the existing
%      singleton*.
%
%      H = EPITOOLS returns the handle to a new EPITOOLS or the handle to
%      the existing singleton*.
%
%      EPITOOLS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in EPITOOLS.M with the given input arguments.
%
%      EPITOOLS('Property','Value',...) creates a new EPITOOLS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before EpiTools_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to EpiTools_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help EpiTools

% Last Modified by GUIDE v2.5 29-Mar-2015 19:09:42

% Begin initialization code - DO NOT EDIT
%
% Add a splash screen before EpiTools loading
if ~nargin;SplashScreen; end

gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @EpiTools_OpeningFcn, ...
    'gui_OutputFcn',  @EpiTools_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);

if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT
% --- Executes just before EpiTools is made visible.
function EpiTools_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to EpiTools (see VARARGIN)
% -------------------------------------------------------------------------
% Exec splash screen 
SplashHandle = findobj('tag','SplashScreenTag');
if ishandle(SplashHandle);close(SplashHandle);end
% -------------------------------------------------------------------------
% Choose default command line output for EpiTools
handles.output = hObject;
% -------------------------------------------------------------------------
% Update handles structure
guidata(hObject, handles);
% -------------------------------------------------------------------------
% Disable warnings for structOnObject (occours when struct is saved in xml)
warning off MATLAB:structOnObject
% -------------------------------------------------------------------------
% Load libraries
stsFunOut = LoadEpiTools();
% -------------------------------------------------------------------------
%set up app-data
setappdata(0  , 'hMainGui'    , gcf);
setappdata(gcf, 'data_specifics', 'none');
setappdata(gcf, 'icy_is_used', 0);
setappdata(gcf, 'icy_is_loaded', 0);
setappdata(gcf, 'icy_path', 'none');
setappdata(gcf, 'settings_objectname', '');
setappdata(gcf, 'execution_memory', struct());
setappdata(gcf, 'settings_execution', '');
setappdata(gcf, 'status_application',stsFunOut);
setappdata(gcf, 'settings_release',[]);
setappdata(gcf, 'settings_licence',[]);
setappdata(gcf, 'server_instances',struct());
setappdata(gcf, 'client_modules',struct());
setappdata(gcf, 'pool_instances',struct());
setappdata(gcf, 'settings_executionuid',...
                ['epitools-',...
                getenv('USER'),...
                '@',...
                char(getHostName(java.net.InetAddress.getLocalHost)),...
                '-',...
                datestr(now,29),...
                '.log']);
% Load release and licence files in EpiTools
if(exist('release.xml','file')==2); release = xml_read('release.xml'); setappdata(gcf, 'settings_release',release);end
if(exist('licence.xml','file')==2); licence = xml_read('licence.xml'); setappdata(gcf, 'settings_licence',licence);end
% -------------------------------------------------------------------------
% Prepare struct containing handles for UI
hUIControls = struct();
setappdata(gcf, 'hUIControls', hUIControls);
% -------------------------------------------------------------------------
%obtain absolute location on system
current_script_path = mfilename('fullpath');
[file_path,~,~] = fileparts(current_script_path);
setappdata(gcf, 'settings_rootpath', file_path);
% -------------------------------------------------------------------------
% Set log settings *device and level*
if(~exist('usersettings.xml', 'file'));generate_empty_settingsfile();end
settingsobj = xml_read('usersettings.xml');
setappdata(gcf, 'settings_execution', settingsobj);
% Open log window
log2dev('***********************************************************','INFO');
log2dev('*      EPITOOLS - IMAGE PROCESSING TOOL FOR EPITHELIA     * ','INFO');
log2dev('***********************************************************','INFO');
% -------------------------------------------------------------------------
% Add special procedure when the main windows is closed
hMainGui = getappdata(0,'hMainGui');
set(hMainGui, 'CloseRequestFcn', {@onMainWindowClose});
set(hMainGui,'Position',[0 0 400 100]);
movegui(hMainGui,'center');
% -------------------------------------------------------------------------
% Installing Clients
installClients();
% -------------------------------------------------------------------------
% Display discaimer
if(strcmp(settingsobj.licence.NDA.ctl_activate.values(find(settingsobj.licence.NDA.ctl_activate.actived)),'on'))
    out = disclaimerGUI();
    waitfor(out);
        if strcmp(out,'Exit')
            onMainWindowClose(hObject, eventdata, handles);
            return;
        end
end
% -------------------------------------------------------------------------
% Create menu dinamically
createMenu(hObject,eventdata,handles);
% -------------------------------------------------------------------------
%Update references
handles_connection(hObject,handles);
% --- Outputs from this function are returned to the command line.
function varargout = EpiTools_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA

diary off;
% Get default command line output from handles structure
%varargout{1} = handles.output;
% --------------------------------------------------------------------
function handles_connection(hObject,handles)
% If the metricdata field is present and the reset flag is false, it means
% we are we are just re-initializing a GUI by calling it from the cmd line
% while it is up. So, bail out as we dont want to reset the data.
hMainGui = getappdata(0, 'hMainGui');
% -------------------------------------------------------------------------
% Log status of previous operations on GUI
% set(handles.statusbar, 'String',getappdata(hMainGui, 'status_application') );
log2dev( getappdata(hMainGui, 'status_application'), 'INFO', 0, hMainGui, 'statusbar' );
% -------------------------------------------------------------------------
if(isappdata(hMainGui,'settings_objectname'))
    if(isa(getappdata(hMainGui,'settings_objectname'),'settings'))
        stgObj = getappdata(hMainGui,'settings_objectname');
        set(handles.figure1, 'Name', ['EpiTools | ', num2str(stgObj.analysis_code), ' - ' , stgObj.analysis_name])
        %LoadControls(hMainGui, stgObj);
        stgObj.refreshTree(hMainGui);
        % -------------------------------------------------------------------------
        % Log status of previous operations on GUI
        log2dev(sprintf('A setting file %s%s%s has been correctly loaded in the framework',...
                        stgObj.analysis_name,...
                        num2str(stgObj.analysis_version),...
                        stgObj.data_extensionmask),...
                'INFO', 0, hMainGui, 'statusbar' );
        % -------------------------------------------------------------------------  
    end 
end
I = imread('./images/backgroundlogo.tif');
h = imshow(I(:,:,1:3), 'Parent', handles.axes8);
set(h, 'AlphaData', I(:,:,4));
% Update handles structure
guidata(hObject, handles);
% --------------------------------------------------------------------
%% Create menu dinamically 
% Action menu is compiled parsing loaded clients with desc_menu field
% valorised.
function createMenu(hObject,eventdata,handles)
% Menu item
mFile = uimenu(hObject,'Label','File'); 
mEdit = uimenu(hObject,'Label','Edit');
mActions = uimenu(hObject,'Label','Actions');
mView = uimenu(hObject,'Label','View');
mDevelopers= uimenu(hObject,'Label','Developers');
mHelp = uimenu(hObject,'Label','Help','Callback', {@MHelp_Callback,handles});
mCredits = uimenu(hObject,'Label','Credits','Callback', {@MCredits_Callback,handles});
% Subitems (FILE)
frh = uimenu(mFile,'Label','New analysis', 'Callback', {@F_New_Callback,handles});
frh = uimenu(mFile,'Label','Open analysis', 'Callback', {@F_Open_Callback,handles});
frh = uimenu(mFile,'Label','Import settings', 'Separator','on', 'Callback', {@F_ImportSettings_Callback,handles});
frh = uimenu(mFile,'Label','Save analysis', 'Separator','on', 'Callback', {@F_Save_Callback,handles});
frh = uimenu(mFile,'Label','Analysis properties', 'Separator','on', 'Callback', {@F_Properties_Callback,handles});
frh = uimenu(mFile,'Label','Exit', 'Separator','on', 'Callback', {@F_Exit_Callback,handles});
% Subitems (EDIT)
frh = uimenu(mEdit,'Label','Undo', 'Enable', 'off', 'Callback', {@E_Undo_Callback,handles});
frh = uimenu(mEdit,'Label','Redo', 'Enable', 'off', 'Callback', {@E_Redo_Callback,handles});
frh = uimenu(mEdit,'Label','Preferences', 'Separator','on','Callback', {@E_Preferences_Callback,handles});
% Subitems (ACTIONS)
% Get all the installed clients 
% (client installation process must have been performed before this step)
client_modules = getappdata(getappdata(0, 'hMainGui'), 'client_modules');
clients = client_modules(2).ref;
a = {clients.menu_uid};
a(cellfun(@isempty,a)) = {NaN};
[~, sortidx] = sort([a{:}]);
for i = sortidx
    if isnan(i); continue; end
    curClient = clients(i);
    if isempty(curClient.desc_menu); continue; end
    frh = uimenu(mActions,'Label',curClient.desc_menu, 'Separator','on','Position',curClient.menu_uid, 'Callback', {@callModule,handles,curClient.uid});
    log2dev(sprintf('Module %s has been correctly loaded...',curClient.desc_menu),'INFO');
end
% frh = uimenu(mActions,'Label','Undo');
% Subitems (VIEW)
frh = uimenu(mView,'Label','Desktop layout');
% Subsubitems (VIEW)
uimenu(frh,'Label','Single mode','Callback', {@V_D_SingleMode_Callback,handles});
uimenu(frh,'Label','Comparative mode','Callback', {@V_D_ComparativeMode_Callback,handles});
uimenu(frh,'Label','Default mode','Callback', {@V_D_DefaultInterface_Callback,handles});
frh = uimenu(mView,'Label','Define working space','Enable', 'off');
% Subitems (DEVELOPERS)
frh = uimenu(mDevelopers,'Label','Install plugin', 'Enable', 'off');
frh = uimenu(mDevelopers,'Label','Remove plugin', 'Enable', 'off');
frh = uimenu(mDevelopers,'Label','Manage plugins', 'Enable', 'off', 'Separator','on');
frh = uimenu(mDevelopers,'Label','Server manager', 'Enable', 'off', 'Separator','on');
frh = uimenu(mDevelopers,'Label','Pool manager', 'Enable', 'off', 'Separator','on');
frh = uimenu(mDevelopers,'Label','Clients manager', 'Enable', 'off', 'Separator','on');
% --------------------------------------------------------------------
%% Menu Callbacks 
function E_Undo_Callback(hObject, eventdata, handles)
% --------------------------------------------------------------------
function E_Redo_Callback(hObject, eventdata, handles)
% --------------------------------------------------------------------
function E_Preferences_Callback(hObject, eventdata, handles)
% hObject    handle to E_Preferences (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

UserSettingsGUI();
% --------------------------------------------------------------------
function F_New_Callback(hObject, eventdata, handles)
% hObject    handle to F_New (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hMainGui = getappdata(0, 'hMainGui');
% Graphics
uihandles_deletecontrols('all');
% Execute procedures required by server-client modules
disconnectPool
SandboxGUIRedesign(0);
stsFunOut = [];
% Check if there is setting file loaded in the application
if(isappdata(hMainGui,'settings_objectname'))
    if(isa(getappdata(hMainGui,'settings_objectname'),'settings'))
        % Ask if you want to save it before generate a new one
        interrupt =  SaveAnalysisFile(getappdata(hMainGui,'settings_objectname'));
        stgObj = getappdata(hMainGui,'settings_objectname');
        if (interrupt == 1);return; else stgObj.createPackage; end
    end
end
% Ask to the user to specify the image directory and the fullpath where the
% analysis file will be stored
strPathAnalysisFile = uigetdir('~','Select the directory where your analysis file will be stored');
if(strPathAnalysisFile)
    % Initialize a new setting file and call the form FilePropertiesGUI
    stgObj = settings();
    stgObj.CreateModule('Main');
    setappdata(hMainGui, 'settings_objectname', stgObj);
    stgObj.data_fullpath = strPathAnalysisFile;
    
else
    return;
end
while(isempty(stsFunOut)==1)
    strPathImages = uigetdir('~','Select the directory containing your images');
    if(strPathImages)
        stgObj.data_imagepath = strPathImages;
        stsFunOut = CreateMetadata(stgObj);
    else
        break;
    end
end
% Continue execution only if the previous passages has been completed
% correctly.
if ~isempty(stsFunOut)
    out = FilePropertiesGUI(getappdata(hMainGui,'settings_objectname'));
    uiwait(out);
    SaveAnalysisFile(stgObj,'ForceSave', true);
    stgObj = getappdata(hMainGui,'settings_objectname');
    % Logging on external device
    diary([stgObj.data_fullpath,'/out-',datestr(now,30),'.log']);
    diary on;
    % Status operations
    min = 0; max=100; value=10;
    log2dev('Parallel computing toolbox availability check...','INFO',0,'hMainGui', 'statusbar',{min,max,value});
    % Parallel
    installed_toolboxes=ver;
    if(any(strcmp('Parallel Computing Toolbox', {installed_toolboxes.Name})))
        if(stgObj.platform_units ~= 1);
            parpool('local',stgObj.platform_units);
        end
    end
    % Status operations
    min = 0; max=100; value=45;
    log2dev('Storing temporary variables...','INFO',0,'hMainGui', 'statusbar',{min,max,value});
    %Check if icy is in use
    stgObj.icy_is_used = getappdata(hMainGui,'icy_is_used');
    % Status operations
    min = 0; max=100; value=65;
    log2dev('Graphics initialization...','INFO',0,'hMainGui', 'statusbar',{min,max,value});
    % Update handles structure
    handles_connection(hObject, handles)
    % Status operations
    min = 0; max=100; value=75;
    log2dev('Pool connection establishing...','INFO',0,'hMainGui', 'statusbar',{min,max,value});
    %connectPool('clipro');% DEBUG
    connectPool(strcat(stgObj.analysis_name,'_default'));
    %connectPool(strcat(stgObj.analysis_name,'_',num2str(randi(100000000))));
    % Status operations
    min = 0; max=100; value=85;
    log2dev('Server connection establishing...','INFO',0,'hMainGui', 'statusbar',{min,max,value});
    % Connect to server instance
    connectServer();
    % Status operations
    min = 0; max=100; value=100;
    log2dev(sprintf('File loading completed for analysis %s generated by %s on %s', stgObj.analysis_name, stgObj.user_name, stgObj.platform_id),'INFO',0,'hMainGui', 'statusbar',{min,max,value});
end
% --------------------------------------------------------------------
function F_Open_Callback(hObject, eventdata, handles)
% hObject    handle to F_Open (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hMainGui = getappdata(0, 'hMainGui');
% Graphics
uihandles_deletecontrols('all');
% Execute procedures required by server-client modules
disconnectPool();
SandboxGUIRedesign(0);
% Check if there is setting file loaded in the application
if(isappdata(hMainGui,'settings_objectname'))
    if(isa(getappdata(hMainGui,'settings_objectname'),'settings'))  
        % Ask if you want to save it before generate a new one
        interrupt = SaveAnalysisFile(getappdata(hMainGui,'settings_objectname'));
        stgObj = getappdata(hMainGui,'settings_objectname');
        if (interrupt == 1);return; else stgObj.createPackage; end
    end
end
[strSettingFileName,strSettingFilePath,~] = uigetfile('~/*.xml','Select analysis file');
% If the user select a file to open
if(strSettingFilePath)
    stgObj = xml_read([strSettingFilePath,strSettingFileName]);
    % Check for validity
    fieldsettings = fields(stgObj);
    if sum(strcmp(fieldsettings,'analysis_code')) == 0
       log2dev(sprintf('EPITOOLS:hMainGui:FOpenCallBack | %s','The selected file is not compatible with this version of EpiTools'),'WARN');
       return;
    end
    % Status operations
    min = 0; max=100; value=1;
    log2dev('Loading file...','INFO',0,'hMainGui', 'statusbar',{min,max,value});
    % Status operations
    min = 0; max=100; value=5;
    log2dev('File integrity check running...','INFO',0,'hMainGui', 'statusbar',{min,max,value});
    % Storing as setting object
    stgObj = settings(stgObj);
    arrayFiles = fields(stgObj.analysis_modules.Main.data);
    tmpFileStruct = {};
    for i=1:numel(arrayFiles)
        idx = arrayFiles(i);
        stgObj.analysis_modules.Main.data.(char(idx)).exec = logical(stgObj.analysis_modules.Main.data.(char(idx)).exec);
        tmpFileStruct(i,:) = struct2cell(stgObj.analysis_modules.Main.data.(char(idx)))';
    end
    stgObj.analysis_modules.Main.data = tmpFileStruct;
    %load([strSettingFilePath,strSettingFileName], '-mat');
    setappdata(hMainGui, 'settings_objectname', stgObj);
    % Global integrity check
    if(DataIntegrityCheck(hObject, handles, strSettingFilePath))
        stgObj = getappdata(hMainGui, 'settings_objectname');
    end
    % Status operations
    min = 0; max=100; value=25;
    log2dev('Folder integrity check running...','INFO',0,'hMainGui', 'statusbar',{min,max,value});
    % Parallel
    installed_toolboxes=ver;
    if(any(strcmp('Parallel Computing Toolbox', {installed_toolboxes.Name})))
        if(stgObj.platform_units ~= 1);
            matlabpool('local',stgObj.platform_units);
        end
    end
    % Status operations
    min = 0; max=100; value=35;
    log2dev('Parallel computing toolbox availability check...','INFO',0,'hMainGui', 'statusbar',{min,max,value});
    %Check if icy is in use
    stgObj.icy_is_used = getappdata(hMainGui,'icy_is_used');
    settings_executionuid = getappdata(hMainGui,'settings_executionuid');
    diary([stgObj.data_fullpath,'/',settings_executionuid]);
    diary on;
    % Status operations
    min = 0; max=100; value=45;
    log2dev('Storing temporary variables...','INFO',0,'hMainGui', 'statusbar',{min,max,value});
    % Activate controls and refresh main window
    handles_connection(hObject, handles)
    % Status operations
    min = 0; max=100; value=65;
    log2dev('Graphics initialization...','INFO',0,'hMainGui', 'statusbar',{min,max,value});
    % Execute procedures required by server-client modules
    % disconnectPool();
    % Status operations
    min = 0; max=100; value=75;
    log2dev('Pool connection establishing...','INFO',0,'hMainGui', 'statusbar',{min,max,value});
    if exist([stgObj.data_fullpath,'/pools'],'dir');
        files = dir( [stgObj.data_fullpath,'/pools']);
        if ~isempty(files)
            for idxFile = 1:numel(files)
                if(~files(idxFile).isdir) 
                    a = regexpi(files(idxFile).name,'(?<=pool_)(.*)(?=.xml)', 'match');
                    if ~isempty(a)
                        copyfile([stgObj.data_fullpath,'/pools/',files(idxFile).name], ['tmp/',files(idxFile).name])
                        connectPool(a{1});
                    end
                end
            end
        else
            connectPool(strcat(stgObj.analysis_name,'_default'));
        end
        %mkdir([settings_obj.data_fullpath,'/pools']); 
        %connectPool(strcat(stgObj.analysis_name,'_default'));
    else
        connectPool(strcat(stgObj.analysis_name,'_default'));
    end
    % Status operations
    min = 0; max=100; value=85;
    log2dev('Server connection establishing...','INFO',0,'hMainGui', 'statusbar',{min,max,value});
    connectServer();
    min = 0; max=100; value=100;
    log2dev(sprintf('File loading completed for analysis %s generated by %s on %s', stgObj.analysis_name, stgObj.user_name, stgObj.platform_id),'INFO',0,'hMainGui', 'statusbar',{min,max,value});
else
    log2dev( getappdata(hMainGui, 'status_application'), 'INFO', 0, hMainGui, 'statusbar' );
end
% --------------------------------------------------------------------
function F_ImportSettings_Callback(hObject, eventdata, handles)
% hObject    handle to F_ImportSettings (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hMainGui = getappdata(0, 'hMainGui');
strRootPath = getappdata(hMainGui,'settings_rootpath');
stgObj = getappdata(hMainGui, 'settings_objectname');

copyfile(fullfile(strRootPath,...
    'images','emblem-notice.png'));
[icoInformation] = imread('emblem-notice.png');


[strSettingFileName,strSettingFilePath,~] = uigetfile('~/*.etl','Select an analysis file to copy the settings from');

% If the user select a file to open
if(strSettingFilePath ~= 0)
    
    tmp = xml_read([strSettingFilePath,strSettingFileName]);
    %tmp = load([strSettingFilePath,strSettingFileName], '-mat', 'stgObj');
    
    stgObj.analysis_modules = tmp.stgObj.analysis_modules;
    
    setappdata(hMainGui, 'settings_objectname', stgObj);
    
    h = msgbox([sprintf('For the current analysis file \n\n analysis>  %s  \n\n',...
        strcat(stgObj.analysis_code,' | ',stgObj.analysis_name,' -  version> ',stgObj.analysis_version)),...
        sprintf('you imported from the analysis file \n\n analysis>  %s \n\n',...
        strcat(tmp.stgObj.analysis_code,' | ',tmp.stgObj.analysis_name,' -  version>',tmp.stgObj.analysis_version)),...
        'all available modules. The operation concluded successfully!'],...
        'Importing operation succesfully completed','custom',icoInformation);
    
end

handles_connection(hObject, handles)
% --------------------------------------------------------------------
function F_Save_Callback(hObject, eventdata, handles)
% hObject    handle to F_Save (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
SaveAnalysisFile(getappdata(getappdata(0, 'hMainGui'), 'settings_objectname'));
% --------------------------------------------------------------------
function F_Properties_Callback(hObject, eventdata, handles)
% hObject    handle to F_Properties (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hMainGui = getappdata(0, 'hMainGui');
obj = getappdata(getappdata(0, 'hMainGui'), 'settings_objectname');
if(getappdata(hMainGui,'settings_objectname') ~= 0)
    out = FilePropertiesGUI(obj);
    waitfor(out);
    out = questdlg('EpiTools will overwrite the current indices. Please DO NOT continue with this operation if you want to preserve the orginal indices and image configurations. ', 'Indices overwriting','Continue','Abort', 'Abort');
    switch out
        case 'Continue'
            prepareModule('bypass-withdrawals');
        case 'Abort'
            return;
    end
else
    msgbox('No analysis file loaded!');
end

% Update handles structure
handles_connection(hObject, handles)
% --------------------------------------------------------------------
function F_Exit_Callback(hObject, eventdata, handles)
% hObject    handle to F_Exit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
onMainWindowClose(hObject, eventdata, handles);
% --------------------------------------------------------------------
function V_D_SingleMode_Callback(hObject, eventdata, handles)
% hObject    handle to V_D_SingleMode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if strcmp(get(handles.('V_D_ComparativeMode'),'Checked'),'on')
    set(handles.('V_D_ComparativeMode'), 'Checked', 'off');
    set(hObject, 'Checked', 'on');
else
    set(hObject, 'Checked', 'on');
end
% --------------------------------------------------------------------
function V_D_ComparativeMode_Callback(hObject, eventdata, handles)
% hObject    handle to V_D_ComparativeMode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if strcmp(get(handles.('V_D_SingleMode'),'Checked'),'on')
    set(handles.('V_D_SingleMode'), 'Checked', 'off');
    set(hObject, 'Checked', 'on'); 
else
    set(hObject, 'Checked', 'on');
end
% --------------------------------------------------------------------
function V_D_DefaultInterface_Callback(hObject, eventdata, handles)
% hObject    handle to V_D_DefaultInterface (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.('V_D_SingleMode'), 'Checked', 'off');
set(handles.('V_D_ComparativeMode'), 'Checked', 'off');
% --------------------------------------------------------------------
function MHelp_Callback(hObject, eventdata, handles)
% hObject    handle to MHelp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
web('http://imls-bg-arthemis.uzh.ch/epitools/');
% --------------------------------------------------------------------
function MCredits_Callback(hObject, eventdata, handles)
% hObject    handle to MCredits (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
frmInfoSplash();
% --------------------------------------------------------------------
%% Toolbar callbacks
function uiNewAnalysisPush_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to uiNewAnalysisPush (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
F_New_Callback(hObject, eventdata, handles);
% --------------------------------------------------------------------
function uiOpenAnalysisPush_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to uiOpenAnalysisPush (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
F_Open_Callback(hObject, eventdata, handles)
% --------------------------------------------------------------------
function uiSaveAnalysisPush_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to uiSaveAnalysisPush (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
F_Save_Callback(hObject, eventdata, handles)
% --------------------------------------------------------------------
function uiImportAnalysisPush_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to uiImportAnalysisPush (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
F_ImportSettings_Callback(hObject, eventdata, handles)
% --------------------------------------------------------------------
function uiIcyVisualizationToggle_OffCallback(hObject, eventdata, handles)
% hObject    handle to uiIcyVisualizationToggle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
use_icy_checkbox_Callback(0);
% --------------------------------------------------------------------
function uiIcyVisualizationToggle_OnCallback(hObject, eventdata, handles)
% hObject    handle to uiIcyVisualizationToggle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

activation_succeeded = use_icy_checkbox_Callback(1);
if(~activation_succeeded)
    set(hObject,'State','off');
end
% --- Executes on button press in use_icy_checkbox.
function icy_is_used = use_icy_checkbox_Callback(ToggleValue)
% hObject    handle to use_icy_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hMainGui = getappdata(0, 'hMainGui');
settingsobj = getappdata(hMainGui, 'settings_execution');

if ToggleValue
    
    icy_path = settingsobj.output.icy.ctl_connectionstring.values;
    icy_is_loaded = getappdata(hMainGui,'icy_is_loaded');
    
    %Check if icy's path was specified
    if(strcmp(icy_path,'none'))
        %user specification if none defined
        icy_path = uigetdir('~/','Please locate /path/to/Icy/plugins/ylemontag/matlabcommunicator');
        if(icy_path == 0) %user cancel
            icy_path = 'none';
        end
    end
    
    %Check if icy functions are already loaded
    if(~icy_is_loaded)
        if(exist([icy_path,'/icy_init.m'],'file'))
            
            log2dev(sprintf('Successfully detected ICY at:%s\n',icy_path),'INFO');
            addpath(icy_path);
            icy_init();
            icy_is_used = 1;
            icy_is_loaded = 1;
        else
            icy_path = 'none';
            icy_is_used = 0;
            errordlg('ICY could not be detected at specified path, please rexecute!');
            log2dev(sprintf('Current icy path is not valid: %s\n',icy_path),'WARN');
        end
    else
        icy_is_used = 1;
    end
    
    %set app data
    %setappdata(hMainGui,'icy_path',icy_path);
    setappdata(hMainGui,'icy_is_loaded',icy_is_loaded);
    setappdata(hMainGui,'icy_is_used',icy_is_used);
    
    if(icy_is_used);mtx = [1 0];else mtx = [0 1];end
    settingsobj.output.icy.ctl_enableicyconnection.actived = mtx;
    settingsobj.output.icy.ctl_connectionstring.values = icy_path;
    
else
    %checkbox is deselected
    setappdata(hMainGui,'icy_is_used',0);
    icy_is_used = 0;
end

setappdata(hMainGui, 'settings_execution',settingsobj);

%set preference in settings object if one exists
if(isappdata(hMainGui,'settings_objectname'))
    if(isa(getappdata(hMainGui,'settings_objectname'),'settings'))
        stgObj = getappdata(hMainGui,'settings_objectname');
        stgObj.icy_is_used = getappdata(hMainGui,'icy_is_used');
    end
end

xml_write('usersettings.xml', settingsobj);
% --------------------------------------------------------------------
function uiExecuteServerQueue_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to uiExecuteServerQueue (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hMainGui = getappdata(0, 'hMainGui');
server_instances = getappdata(hMainGui, 'server_instances');
client_modules = getappdata(hMainGui, 'client_modules');
pool_instances = getappdata(hMainGui, 'pool_instances');
% Remapping
server = server_instances(2).ref;

% clients = client_modules(2).ref;
% 
% for i = 1:size(pool_instances(2:end),2)
%     if (pool_instances(i+1).ref.active)
%         %server.receiveMessage(clients(1),pool_instances(i+1).ref);
%         server.receiveMessage(clients(4),pool_instances(i+1).ref);
%     end
% end

% Forcing execution
server.forceExecutionQueue;
% --------------------------------------------------------------------
function uiManagePoolActivation_ClickedCallback(hObject, eventdata,handles)
hMainGui = getappdata(0, 'hMainGui');
pool_instances = getappdata(hMainGui, 'pool_instances');
if(numel(pool_instances) >=2)
    poold_PoolActivationManagerGUI;
end
% --------------------------------------------------------------------
function uiFlushServerQueue_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to uiFlushServerQueue (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
server_instances = getappdata(getappdata(0, 'hMainGui'), 'server_instances');
server_instances(2).ref.FlushQueue;
setappdata(getappdata(0, 'hMainGui'),'server_instances',server_instances);
% --------------------------------------------------------------------
function uiImageLayersToggle_OffCallback(hObject, eventdata, handles)
% hObject    handle to uiImageLayersToggle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if  uihandles_exists( 'GraphicHandleCmpDisplay' )
    uihandles_deletecontrols( 'GraphicHandleCmpDisplay' );
    log2dev( 'Standard visualisation mode actived', 'INFO', 0, 'hMainGui', 'statusbar' );
end
% --------------------------------------------------------------------
function uiImageLayersToggle_OnCallback(hObject, eventdata, handles)
% hObject    handle to uiImageLayersToggle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
inputs(1) = getappdata(0, 'hMainGui');
uihandles_deletecontrols( 'uiSWslider' );
uihandles_deletecontrols( 'uiSWImage' );
uihandles_deletecontrols( 'uiSWFrameNumLabel' );
uihandles_deletecontrols( 'uiSWFrameNumEdit' );
uihandles_deletecontrols( 'uiBannerDescription' );
uihandles_deletecontrols( 'uiBannerContenitor' );
uihandles_deletecontrols( 'GraphicHandleSingleVDisplay' );
[status,argout] = dataexplorer_cmpview( inputs );
if ~status;
    uihandles_savecontrols( argout(1).description ,argout(1).object );
    log2dev( 'Comparative visualisation mode actived', 'INFO', 0, 'hMainGui', 'statusbar' );
end
% --------------------------------------------------------------------
%% Support Functions
function SplashScreenHandle = SplashScreen
% Splash screen before EpiTools loading
addpath('./src_support/module_xml');
logo = imread('./images/epitools_logo.png','png');
SplashScreenHandle = figure('MenuBar','None','NumberTitle','off','color',...
                            [1 1 1],'tag','SplashScreenTag','name',...
                            'EpiTools is loading...','color',[0.7,0.7,0.9],...
                            'Visible', 'off');
                        
iptsetpref('ImshowBorder','tight');
imshow(logo);

movegui(SplashScreenHandle,'center');
set(SplashScreenHandle, 'Visible', 'on');

if(exist('release.xml','file'))
    release = xml_read('release.xml');
else
    error('EpiTools installation is currupted. Exiting....');
end

if(exist('licence.xml','file'))
    licence = xml_read('licence.xml');

    
else
    warn('No licence file has been found in EpiTools directory');
    licence.customer.name = 'Unknown';
    licence.customer.lastname = '';
    licence.customer.email = '' ;
    licence.key.validity = 0;
end

text = uicontrol('Parent', SplashScreenHandle,...
                'Style','text',...
                'HorizontalAlignment', 'left',...
                'FontName','Helvetica Neue',...
                'String',sprintf('%s V%uR%uB%s licensed to %s %s (%s) for %u days',...
                                release.programm_name,...
                                release.version,...
                                release.release*100,...
                                release.build,...
                                licence.customer.name,...
                                licence.customer.lastname,...
                                licence.customer.email, ...
                                licence.key.validity),...
                'Units', 'normalized',...
                'Position', [0 0 1 0.05],...
                'BackgroundColor', [0 0 0],...
                'ForegroundColor', [1 1 1]);

drawnow;
% --------------------------------------------------------------------
function onMainWindowClose(hObject, eventdata, handles)
% On Main Windows Close function    
hMainGui = getappdata(0, 'hMainGui');
hLogGui = getappdata(0, 'hLogGui');
% Since the current function is invoked without passing handles, then
% recover them with
handles = guidata(hMainGui);
% Check if there is setting file loaded in the application
if(isappdata(hMainGui,'settings_objectname'))
    if(isa(getappdata(hMainGui,'settings_objectname'),'settings'))
        % Ask if you want to save it before closing the application
        output = SaveAnalysisFile(getappdata(hMainGui,'settings_objectname'));
        %waitfor(output);
        stgObj = getappdata(hMainGui, 'settings_objectname');
        if (output == 1);return; else stgObj.createPackage; end
        %matlabpool is unrecognized on platforms without the Paralell Computing toolbox
        if(stgObj.platform_units ~= 1) if (matlabpool('size') > 0); matlabpool close; end ; end    
    end
end
settings_executionuid = getappdata(hMainGui, 'settings_executionuid');
log2dev('***********************************************************','INFO');
log2dev(sprintf('* End session %s * ',settings_executionuid),'INFO');
log2dev('***********************************************************','INFO');
if exist(['~/',settings_executionuid], 'file')
    delete(['~/',settings_executionuid]);
end
disconnectPool;
delete(hLogGui);
delete(hMainGui);
close all;
% --------------------------------------------------------------------
function prepareModule(options) 
if nargin < 1; options = ''; end
obj = getappdata(getappdata(0, 'hMainGui'), 'settings_objectname');
server_instances = getappdata(getappdata(0, 'hMainGui'), 'server_instances');
server = server_instances(2).ref;
% Status operations
minv = 0; maxv=7;
log2dev('Preparing analysis module execution. Please wait...','INFO',0,'hMainGui', 'statusbar',{minv,maxv,1});
% ----------------------------------------------
% [1] Call indexing module
strModuleName = 'Indexing';
% Duplicate setting objects and save content
int = settings();
int.inheritSettings(obj);
log2dev('Preparing analysis module execution. Please wait...','INFO',0,'hMainGui', 'statusbar',{minv,maxv,2});
% Calling complementary indexing function
proceed = int.initialiseModule(strModuleName);
if (~isempty(options) || strcmp(options,'bypass-withdrawals')>0); proceed = true; end
log2dev('Preparing analysis module execution. Please wait...','INFO',0,'hMainGui', 'statusbar',{minv,maxv,3});
%if proceed;dataindexing_caller(options,int);end
dataindexing_caller(options,int);
log2dev('Preparing analysis module execution. Please wait...','INFO',0,'hMainGui', 'statusbar',{minv,maxv,4});
%server.forceExecutionQueue;
log2dev('Preparing analysis module execution. Please wait...','INFO',0,'hMainGui', 'statusbar',{minv,maxv,5});
% ----------------------------------------------
% [2] Call loader module
%if proceed;loader_caller(options,obj);end
loader_caller(options,obj)
log2dev('Preparing analysis module execution. Please wait...','INFO',0,'hMainGui', 'statusbar',{minv,maxv,6});
%server.forceExecutionQueue;
log2dev('Preparing analysis module execution. Please wait...','INFO',0,'hMainGui', 'statusbar',{minv,maxv,7});
% --------------------------------------------------------------------
function callModule(hObject,eventdata,handles,strModuleName)
obj = getappdata(getappdata(0, 'hMainGui'), 'settings_objectname');
client_modules = getappdata(getappdata(0, 'hMainGui'), 'client_modules');
clients = client_modules(2).ref;
% [2]
% Duplicate setting objects and save content
int = settings();
int.inheritSettings(obj);
proceed = int.initialiseModule(strModuleName);
if ~proceed; return; end
% Calling main function
initialisePoolPath(int);
% Prepare module to execution (calling indexing and loader if needed)
prepareModule();
uiwait(eval(clients(strcmp({clients.uid},strModuleName)).guilauncher));
handles_connection(hObject,handles)
