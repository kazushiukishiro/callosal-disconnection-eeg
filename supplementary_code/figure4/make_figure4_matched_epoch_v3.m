function outDir = make_figure4_matched_epoch_v3(inputDir)
%MAKE_FIGURE4_MATCHED_EPOCH_V3 Draw the checked Figure 4 with distinct palettes.
% Based on the working v2 CSV-based plotting function, NOT the old CORE plot.
% V3 changes appearance only: separate B/C palettes; C controls use dashed,
% open-marker lines; C WTC uses a darker, slightly thicker solid line.
% All text, including panel letters, explicitly uses Arial.
% CSV parsing, validation, row selection, means, SEMs, F/P annotations and
% export dimensions are retained from v2. No statistical analysis is rerun.
%
% Usage: outDir = make_figure4_matched_epoch_v3;
% Optional: outDir = make_figure4_matched_epoch_v3(inputDir);
% Place all five canonical CSVs in the sibling inputs folder.
% Matched rows produce main Figure 4; Original rows produce the supplement.
% Existing study files and figures are not overwritten.
% Intended for MATLAB R2026a. Not runtime-tested in MATLAB here.

packageDir = fileparts(mfilename('fullpath'));
if nargin < 1 || isempty(inputDir)
    inputDir = fullfile(packageDir,'inputs');
end
inputDir = char(inputDir);
if ~isfolder(inputDir)
    error('CCFigure4:InputFolder','Input folder not found: %s',inputDir);
end
names = {'CC_matched_epoch_descriptive.csv','CC_matched_epoch_models.csv', ...
    'CC_matched_epoch_contrasts.csv','CC_matched_epoch_status.csv', ...
    'CC_matched_source_verification.csv'};
T = cell(size(names));
for k = 1:numel(names)
    f = fullfile(inputDir,names{k});
    if ~isfile(f)
        error('CCFigure4:Input','Required CSV missing: %s',f);
    end
    T{k} = readResultCSV(f,names{k});
end
D = T{1}; M = T{2}; Q = T{3}; S = T{4}; V = T{5};
requireColumns(D,{'Selection','Metric','State','N_Raw','MeanRaw','SDRaw', ...
    'SEMRaw','N_Normalized','MeanNormalized','SDNormalized', ...
    'SEMNormalized','RegionalGroups','FiniteEpochRegionRows'});
requireColumns(M,{'Model','Term','FStat','DF1','DF2','P_Unadjusted', ...
    'N_RegionalObservations','FitMethod','DFMethod'});
requireColumns(S,{'Module','Status'});
requireColumns(V,{'AggregateMatch'});
requireColumns(Q,{'Model','Method','Contrast','Estimate','CI_Lower','CI_Upper'});
if isempty(V) || ~all(V.AggregateMatch==1)
    error('CCFigure4:Verification','Not all source comparisons passed.');
end
mods = {'SourceVerification','MatchedCoverage','WTC_primary_reference', ...
    'dwPLI','Delta','Theta','Alpha','Beta','RMS','Power1_40', ...
    'RelativePower4_13','FrequencyInteraction','dwPLI_Bootstrap'};
for k = 1:numel(mods)
    idx = string(S.Module)==mods{k};
    if nnz(idx)~=1
        error('CCFigure4:Status','Missing/duplicate status for %s.',mods{k});
    end
    expected = "COMPLETED";
    if k<=2, expected="PASS"; end
    if string(S.Status(idx))~=expected
        error('CCFigure4:Status','Review analysis status for %s before plotting.',mods{k});
    end
end
metrics = {'WTC','dwPLI','Delta','Theta','Alpha','Beta', ...
    'RMS','Power1_40','RelativePower4_13'};
for sel = ["Matched","Original"]
    for k=1:numel(metrics)
        r=seriesRows(D,sel,metrics{k});
        validateSeries(r,false);
        if ~strcmp(metrics{k},'dwPLI'), validateSeries(r,true); end
    end
end
% Verify equal matched sample/epoch counts across the Figure 4 metrics.
ref=seriesRows(D,"Matched",'WTC');
for k=2:numel(metrics)
    r=seriesRows(D,"Matched",metrics{k});
    for fld={'N_Raw','RegionalGroups','FiniteEpochRegionRows'}
        if ~isequal(r.(fld{1}),ref.(fld{1}))
            error('CCFigure4:Counts','Matched counts differ for %s.',metrics{k});
        end
    end
    if ~strcmp(metrics{k},'dwPLI') && ~isequal(r.N_Normalized,ref.N_Normalized)
        error('CCFigure4:Counts','Matched normalized N differs for %s.',metrics{k});
    end
end
Astats=modelRow(M,'dwPLI','State');
Bstats=modelRow(M,'FrequencyInteraction','State:FrequencyBand');
if Astats.N_RegionalObservations~=sum(ref.RegionalGroups) || ...
        Bstats.N_RegionalObservations~=4*sum(ref.RegionalGroups)
    error('CCFigure4:ModelN','Model observation counts and plotted input differ.');
end

% Create an isolated, permanent subfolder inside this extracted package.
outputParent=fullfile(packageDir,'output');
if ~isfolder(outputParent), mkdir(outputParent); end
[~,uniqueName]=fileparts(tempname);
outDir=fullfile(outputParent,['Figure4_' uniqueName]);
[ok,msg]=mkdir(outDir);
if ~ok, error('CCFigure4:Output','Cannot create output folder: %s',msg); end
inputCopy=fullfile(outDir,'inputs_used'); mkdir(inputCopy);
for k=1:numel(names), copyfile(fullfile(inputDir,names{k}),fullfile(inputCopy,names{k})); end
writetable(D(string(D.Selection)=="Matched",:), ...
    fullfile(outDir,'Figure4_matched_source_values.csv'));

% Save explanatory text BEFORE graphics export, including interpretation limits.
fid=fopen(fullfile(outDir,'README_outputs.txt'),'w','n','UTF-8');
if fid<0, error('CCFigure4:Output','Cannot write output notes.'); end
cleanFile=onCleanup(@() fclose(fid));
fprintf(fid,'POST HOC EPOCH-MATCHED FIGURE 4 - COLOUR VERSION 3\n');
fprintf(fid,'B: frequency palette, solid filled markers. C: separate metric palette.\n');
fprintf(fid,'C: WTC dark solid/filled; controls dashed/open. All fonts Arial.\n');
fprintf(fid,'Figures use supplied group-level CSVs only; no models were refitted.\n');
fprintf(fid,'Main figure: Matched rows. Supplement: Original rows.\n');
fprintf(fid,'A/B: raw patient means +/- SEM. C: within-patient Pre-normalized means +/- SEM.\n');
fprintf(fid,'F/P labels on the matched figure are imported from the matched-model CSV.\n');
fprintf(fid,'P values are unadjusted. The raw-scale models do not test normalized between-metric differences.\n');
fprintf(fid,'Pre/Post sample availability differs; this is not a four-state complete-case subset.\n');
fprintf(fid,'Matching across metrics does not force an identical set of regions across surgical states.\n');
fprintf(fid,'The original-epoch supplement is descriptive; no matched-model F/P is applied to it.\n');
fprintf(fid,'Keep original and matched results and document the post hoc nature of matching.\n');
fprintf(fid,'MATLAB version used for this export: %s\n',version);
clear cleanFile

figMatched=drawPanels(D,"Matched",Astats,Bstats);
exportSet(figMatched,outDir,'Figure4_matched_epoch');
figOriginal=drawPanels(D,"Original",[],[]);
exportSet(figOriginal,outDir,'Supplementary_original_epoch_selection');
fprintf('\nFigures and source copies saved in:\n%s\n',outDir);
fprintf('No original study data, models or figures were overwritten.\n');
end

function T=readResultCSV(fileName,baseName)
% Fixed schemas for the five unmodified CSVs supplied with this package.
% Never infer headers from data (the status file contains only text).
switch baseName
    case 'CC_matched_epoch_descriptive.csv'
        names={'Selection','Metric','State','N_Raw','MeanRaw','SDRaw', ...
            'SEMRaw','N_Normalized','MeanNormalized','SDNormalized', ...
            'SEMNormalized','RegionalGroups','FiniteEpochRegionRows'};
        textNames={'Selection','Metric','State'};
    case 'CC_matched_epoch_models.csv'
        names={'Model','Term','FStat','DF1','DF2','P_Unadjusted', ...
            'N_RegionalObservations','FitMethod','DFMethod'};
        textNames={'Model','Term','FitMethod','DFMethod'};
    case 'CC_matched_epoch_contrasts.csv'
        names={'Model','Method','Contrast','N','N_Unit','Estimate','SE', ...
            'DF','P_Unadjusted','CI_Lower','CI_Upper','ProportionNegative'};
        textNames={'Model','Method','Contrast','N_Unit'};
    case 'CC_matched_epoch_status.csv'
        names={'Module','Status','Detail'};
        textNames=names;
    case 'CC_matched_source_verification.csv'
        names={'Family','Metric','State','CandidateRegionalGroups', ...
            'SavedRegionalGroups','CommonRegionalGroups', ...
            'MissingInCandidate','MissingInSaved','MeanMismatchGroups', ...
            'MaxAbsMeanDifference','CountMismatchGroups', ...
            'SavedCountAvailable','AggregateMatch','Interpretation'};
        textNames={'Family','Metric','State','Interpretation'};
    otherwise
        error('CCFigure4:CSVSchema','No CSV schema defined for %s.',baseName);
end

% Check the actual header, rather than attaching names to an unknown file.
fid=fopen(fileName,'r','n','UTF-8');
if fid<0
    error('CCFigure4:CSVOpen','Cannot open CSV: %s',fileName);
end
closer=onCleanup(@() fclose(fid));
header=fgetl(fid);
clear closer
if ~ischar(header)
    error('CCFigure4:CSVEmpty','CSV has no first line: %s',fileName);
end
if ~isempty(header) && header(1)==char(65279)
    header=header(2:end); % Optional UTF-8 BOM, not a data character.
end
expectedHeader=strjoin(names,',');
if ~strcmp(header,expectedHeader)
    error('CCFigure4:CSVHeader', ...
        ['Unexpected first CSV line in:\n%s\n' ...
         'Expected: %s\nFound: %s\n' ...
         'Use the unmodified inputs supplied in this package.'], ...
        fileName,expectedHeader,header);
end

% Avoid detectImportOptions entirely. Read all rows after the checked header.
types=repmat({'double'},1,numel(names));
isText=ismember(names,textNames);
types(isText)={'string'};
opts=delimitedTextImportOptions('NumVariables',numel(names));
opts.VariableNamingRule='preserve';
opts.VariableNames=names;
opts.VariableTypes=types;
opts.Delimiter=',';
opts.DataLines=[2 Inf];
opts.VariableNamesLine=0; % Header already checked; supplied names used below.
opts.RowNamesColumn=0;
opts.VariableUnitsLine=0;
opts.VariableDescriptionsLine=0;
opts.Encoding='UTF-8';
opts.ExtraColumnsRule='error';
opts.ImportErrorRule='error';
opts.EmptyLineRule='skip';
opts.MissingRule='fill'; % Preserve the recorded NaN fields; never drop rows.
if any(~isText)
    opts=setvaropts(opts,names(~isText),'TreatAsMissing',{'NaN'},'FillValue',NaN);
end
T=readtable(fileName,opts,'ReadVariableNames',false,'ReadRowNames',false);
if ~isequal(T.Properties.VariableNames,names)
    error('CCFigure4:CSVNames','Imported column names differ from checked header.');
end
if isempty(T)
    error('CCFigure4:CSVNoRows','No data rows imported: %s',fileName);
end
fprintf('CSV read: %s | %d rows x %d columns\n',baseName,height(T),width(T));
if strcmp(baseName,'CC_matched_epoch_status.csv')
    disp(T(:,{'Module','Status'}));
end
end

function requireColumns(T,names)
missing=setdiff(names,T.Properties.VariableNames);
if ~isempty(missing)
    error('CCFigure4:Columns','Missing columns: %s',strjoin(missing,', '));
end
end

function R=seriesRows(D,selection,metric)
states=["Pre","Anterior","Posterior","Post"];
ix=zeros(4,1);
for j=1:4
    hit=string(D.Selection)==selection & string(D.Metric)==metric & string(D.State)==states(j);
    if nnz(hit)~=1
        error('CCFigure4:Rows','Expected one %s/%s/%s row.',selection,metric,states(j));
    end
    ix(j)=find(hit);
end
R=D(ix,:);
end

function validateSeries(R,isNorm)
if isNorm
    n=R.N_Normalized; a=R.MeanNormalized; s=R.SDNormalized; e=R.SEMNormalized;
else
    n=R.N_Raw; a=R.MeanRaw; s=R.SDRaw; e=R.SEMRaw;
end
if any(~isfinite([n;a;s;e])) || any(n<2 | n~=fix(n)) || any(s<0 | e<0)
    error('CCFigure4:Values','Non-finite/invalid plotted mean, N, SD or SEM.');
end
if any(abs(e-s./sqrt(n))>1e-9.*max(1,abs(e)))
    error('CCFigure4:SEM','CSV SEM does not equal SD/sqrt(N).');
end
if isNorm && abs(a(1)-100)>1e-8
    error('CCFigure4:Pre','Normalized Pre is not 100.');
end
end

function R=modelRow(M,model,term)
hit=string(M.Model)==model & string(M.Term)==term;
if nnz(hit)~=1, error('CCFigure4:Model','Required model/term not unique.'); end
R=M(hit,:);
if any(~isfinite([R.FStat,R.DF1,R.DF2,R.P_Unadjusted])) || ...
        R.P_Unadjusted<=0 || R.P_Unadjusted>1
    error('CCFigure4:Model','Invalid F/P fields.');
end
if string(R.FitMethod)~="ML" || lower(string(R.DFMethod))~="satterthwaite"
    error('CCFigure4:ModelMethod','Unexpected model fitting/inference method.');
end
end

function fig=drawPanels(D,selection,Astats,Bstats)
% Appearance settings are independent from all numerical input processing.
x=1:4;
markers={'o','s','d','^'};

% Panel A: retain the existing dwPLI blue.
colA=[0.00 0.35 0.75];

% Panel B: frequency bands (solid lines and filled markers).
colB.delta=[0.00 0.45 0.74];
colB.theta=[0.85 0.33 0.10];
colB.alpha=[0.49 0.18 0.56];
colB.beta =[0.00 0.60 0.50];
bandColors=[colB.delta; colB.theta; colB.alpha; colB.beta];

% Panel C: metrics, not frequency bands.
% Use dark brown instead of another orange close to the theta colour.
colC.wtc  =[0.10 0.10 0.10];
colC.rms  =[0.00 0.55 0.25];
colC.broad=[0.55 0.32 0.12];
colC.rel  =[0.75 0.20 0.55];
controlColors=[colC.wtc; colC.rms; colC.broad; colC.rel];

% WTC: solid, filled. Other metrics: dashed, open markers.
controlStyles={'-','--','--','--'};
controlFaces={colC.wtc,'white','white','white'};
controlWidths=[1.70 1.35 1.35 1.35];

fig=figure('Color','w','Units','centimeters', ...
    'Position',[2 2 18.5 7.4], ...
    'Name',['Figure 4 - ' char(selection) ' - Colours v3'], ...
    'NumberTitle','off');
tl=tiledlayout(fig,1,3,'TileSpacing','compact','Padding','compact');

% ---------------- PANEL A: dwPLI ----------------
axA=nexttile(tl,1);
hold(axA,'on');
r=seriesRows(D,selection,'dwPLI');
plotSeries(axA,x,r.MeanRaw,r.SEMRaw,colA,'o');
styleAxis(axA,'Mean dwPLI','Phase-lag-sensitive connectivity','A');
ylim(axA,[0 .055]);
yticks(axA,0:.01:.05);
if selection=="Matched"
    statText(axA,{'State effect',fText(Astats),pText(Astats.P_Unadjusted)});
else
    statText(axA,{'Original epoch selection','Descriptive means +/- SEM'});
end

% ---------------- PANEL B: frequency bands ----------------
axB=nexttile(tl,2);
hold(axB,'on');
hB=gobjects(1,4);
bands={'Delta','Theta','Alpha','Beta'};
for j=1:4
    r=seriesRows(D,selection,bands{j});
    hB(j)=plotSeries(axB,x,r.MeanRaw,r.SEMRaw, ...
        bandColors(j,:),markers{j});
end
styleAxis(axB,'Mean interhemispheric WTC','Frequency-resolved WTC','B');
ylim(axB,[.285 .53]);
yticks(axB,.30:.05:.50);
if selection=="Matched"
    statText(axB,{'State \times frequency band', ...
        fText(Bstats),pText(Bstats.P_Unadjusted)});
end
lg=legend(axB,hB,bands,'Location','southwest','Box','off');
set(lg,'FontName','Arial','FontSize',6.6,'TextColor','k');

% ---------------- PANEL C: signal-level controls ----------------
axC=nexttile(tl,3);
hold(axC,'on');
hC=gobjects(1,4);
cm={'WTC','RMS','Power1_40','RelativePower4_13'};
for j=1:4
    r=seriesRows(D,selection,cm{j});
    hC(j)=plotSeries(axC,x,r.MeanNormalized,r.SEMNormalized, ...
        controlColors(j,:),markers{j},controlStyles{j}, ...
        controlFaces{j},controlWidths(j));
end
yline(axC,100,'--','Color',[.55 .55 .55], ...
    'LineWidth',.6,'HandleVisibility','off');
styleAxis(axC,'Normalized value (% of Pre)','Signal-level controls','C');
ylim(axC,[75 120]);
yticks(axC,80:10:120);
lg=legend(axC,hC,{'WTC','RMS','Broadband power','Relative 4-13 Hz power'}, ...
    'Location','southwest','Box','off');
set(lg,'FontName','Arial','FontSize',6.3,'TextColor','k');

% Includes panel letters and legend text; no global defaults are changed.
fontname(fig,'Arial');
drawnow;
end

function h=plotSeries(ax,x,y,e,col,marker,lineStyle,faceColor,lineWidth)
% Defaults retain the v2 line/marker settings for panels A and B.
if nargin<7, lineStyle='-'; end
if nargin<8, faceColor=col; end
if nargin<9, lineWidth=1.35; end
h=errorbar(ax,x,y(:)',e(:)', ...
    'LineStyle',lineStyle,'Marker',marker,'Color',col, ...
    'MarkerFaceColor',faceColor,'MarkerEdgeColor',col, ...
    'LineWidth',lineWidth,'MarkerSize',4.5,'CapSize',4);
end

function styleAxis(ax,yl,ttl,letter)
set(ax,'FontName','Arial','FontSize',7.5,'LineWidth',.8,'TickDir','out', ...
    'Box','off','Color','w','XColor','k','YColor','k', ...
    'XLim',[.75 4.25],'XTick',1:4, ...
    'XTickLabel',{'Pre','Anterior','Posterior','Post'}, ...
    'XTickLabelRotation',0);
ylabel(ax,yl,'FontName','Arial','FontSize',8, ...
    'Color','k','Interpreter','none');
title(ax,ttl,'FontName','Arial','FontSize',8, ...
    'FontWeight','normal','Color','k','Interpreter','none');
text(ax,-.14,1.065,letter,'Units','normalized','FontName','Arial', ...
    'FontSize',10,'FontWeight','bold','Color','k', ...
    'Clipping','off','Interpreter','none');
end

function statText(ax,lines)
text(ax,.035,.985,lines,'Units','normalized','VerticalAlignment','top', ...
    'HorizontalAlignment','left','FontName','Arial','FontSize',6.4, ...
    'Color',[.25 .25 .25],'Interpreter','tex');
end

function s=fText(R)
s=sprintf('F(%g, %.2f) = %.2f',R.DF1,R.DF2,R.FStat);
end

function s=pText(p)
e=floor(log10(p));
c=p/(10^e);
s=sprintf('P = %.2f \\times 10^{%d}',c,e);
end

function exportSet(fig,outDir,stem)
% Same physical size and export settings as v2.
% EPS/PDF: vector RGB. TIFF: 600 dpi. PNG: 300 dpi.
if ~isgraphics(fig,'figure')
    error('CCFigure4:Figure','Figure was closed or deleted before export.');
end
fontname(fig,'Arial');
drawnow;
common={'BackgroundColor','white','Colorspace','rgb','Units','centimeters', ...
    'Width',18.5,'Height',7.4,'PreserveAspectRatio','on'};
exportgraphics(fig,fullfile(outDir,[stem '.pdf']),'ContentType','vector',common{:});
exportgraphics(fig,fullfile(outDir,[stem '.eps']),'ContentType','vector',common{:});
exportgraphics(fig,fullfile(outDir,[stem '.tif']),'Resolution',600,common{:});
exportgraphics(fig,fullfile(outDir,[stem '.png']),'Resolution',300,common{:});
for ext={'.pdf','.eps','.tif','.png'}
    f=fullfile(outDir,[stem ext{1}]);
    info=dir(f);
    if isempty(info) || info.bytes==0
        error('CCFigure4:Export','Export not created: %s',f);
    end
    fprintf('Saved: %s\n',f);
end
end
