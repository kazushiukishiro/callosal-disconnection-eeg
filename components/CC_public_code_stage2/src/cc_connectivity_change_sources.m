function T = cc_connectivity_change_sources(W,E)
%CC_CONNECTIVITY_CHANGE_SOURCES Preserve primary vs exact-time provenance.
% NEW in-memory public helper derived from the documented metric definitions.
% W: CaseNo, State, Region, Value (one row per subject/state/region).
% E: CaseNo, State, ConnectionType, MeanWTC (one per subject/state/type).
% It neither joins clinical data nor changes follow-up eligibility.
% No external files or base-workspace variables are read.
assert(istable(W)&&istable(E),'CCPublic:SourceInput','Table inputs required.');
assert(all(ismember({'CaseNo','State','Region','Value'},W.Properties.VariableNames)), ...
    'CCPublic:SourceColumns','Primary columns missing.');
assert(all(ismember({'CaseNo','State','ConnectionType','MeanWTC'},E.Properties.VariableNames)), ...
    'CCPublic:SourceColumns','Exact-time columns missing.');
W.CaseNo=string(W.CaseNo);W.State=string(W.State);W.Region=string(W.Region);
E.CaseNo=string(E.CaseNo);E.State=string(E.State);E.ConnectionType=string(E.ConnectionType);
states=["Pre","Anterior","Posterior","Post"];
assert(all(ismember(W.State,states))&&all(ismember(E.State,states)), ...
    'CCPublic:SourceStates','Unexpected state.');
assert(all(ismember(E.ConnectionType,["Intra","Inter"])), ...
    'CCPublic:SourceType','Unexpected connection type.');
assert(~any(isinf(W.Value))&&~any(isinf(E.MeanWTC)), ...
    'CCPublic:SourceInfinite','Infinite input values are not supported.');
assert(size(unique([W.CaseNo W.State W.Region],'rows'),1)==height(W), ...
    'CCPublic:SourceDuplicate','Duplicate primary keys.');
assert(size(unique([E.CaseNo E.State E.ConnectionType],'rows'),1)==height(E), ...
    'CCPublic:SourceDuplicate','Duplicate exact-time keys.');
ids=union(W.CaseNo,E.CaseNo); n=numel(ids);
wp=nan(n,4);ei=nan(n,4);en=nan(n,4);
for k=1:n
    for s=1:4
        v=W.Value(W.CaseNo==ids(k)&W.State==states(s));
        if ~isempty(v),wp(k,s)=mean(v,'omitnan');end
        v=E.MeanWTC(E.CaseNo==ids(k)&E.State==states(s)&E.ConnectionType=="Inter");
        if ~isempty(v),ei(k,s)=v;end
        v=E.MeanWTC(E.CaseNo==ids(k)&E.State==states(s)&E.ConnectionType=="Intra");
        if ~isempty(v),en(k,s)=v;end
    end
end
T=table(ids,wp(:,1)-wp(:,4),wp(:,2)-wp(:,3), ...
    ei(:,1)-ei(:,4),ei(:,2)-ei(:,3), ...
    (ei(:,1)-ei(:,4))-(en(:,1)-en(:,4)), ...
    'VariableNames',{'CaseNo','Primary_PrePost','Primary_AnteriorPosterior', ...
    'Exact_PrePost','Exact_AnteriorPosterior','Exact_Selective'});
assert(~any(isfinite(T.Exact_Selective)&~isfinite(T.Exact_PrePost)), ...
    'CCPublic:SourceSubset','Selective must be a subset of exact-time PrePost.');
end
