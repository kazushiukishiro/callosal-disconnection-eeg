function P = cc_clinical_test_plan()
%CC_CLINICAL_TEST_PLAN Explicit source routing; no significance selection.
% Laterality is evaluated for BOTH source choices and labelled separately.
% This does not claim to identify the exact clinical Table 5C source.
rows=cell(0,5);
vars=["AgeOnset","AgeSurgery","Duration"];
exact=["Exact_PrePost","Exact_AnteriorPosterior","Exact_Selective"];
primary=["Primary_PrePost","Primary_AnteriorPosterior","Exact_Selective"];
for v=vars
    for m=exact
        rows(end+1,:)={"Continuous_"+v+"_"+m,"Spearman",v,m,"Exact-time"}; %#ok<AGROW>
    end
end
for m=primary(1:2)
    rows(end+1,:)={"OnsetSourceSensitivity_"+m,"Spearman","AgeOnset",m, ...
        "Primary (post hoc source sensitivity)"}; %#ok<AGROW>
end
for v=["Sex","MRIAbnormality"]
    for j=1:3
        source="Primary";if j==3,source="Exact-time";end
        rows(end+1,:)={"Binary_"+v+"_"+primary(j),"RankSum",v,primary(j),source}; %#ok<AGROW>
    end
end
for v=["OverallOutcome","DropOutcome"]
    for j=1:3
        source="Primary";if j==3,source="Exact-time";end
        rows(end+1,:)={"Outcome_"+v+"_"+primary(j),"Spearman",v,primary(j),source}; %#ok<AGROW>
    end
end
for m=[primary(1:2),exact]
    source="Exact-time";
    if startsWith(m,"Primary_"),source="Primary";end
    rows(end+1,:)={"Laterality_"+m,"KW","MRILaterality",m,source}; %#ok<AGROW>
end
P=cell2table(rows,'VariableNames',{'RowID','Test','Variable','Metric','Source'});
end
