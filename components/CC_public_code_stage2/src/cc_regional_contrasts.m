function Q = cc_regional_contrasts(m)
%CC_REGIONAL_CONTRASTS NEW public wrapper for the 15 regional contrasts.
% Model must use Pre and CP as references with State*Region fixed effects.
% Coefficient names, not numerical coefficient positions, define contrasts.
% Satterthwaite tests and 95% intervals; Holm across all 15 P values.
C=m.Coefficients;names=string(C.Name);beta=C.Estimate;
early=["Pre","Anterior","Posterior"];
late=["Anterior","Posterior","Post"];
regions=["FT","T","TO","CP","PO"];
rows=cell(0,8);
for r=1:5
    for j=1:3
        H=stateVector(names,late(j),regions(r))-stateVector(names,early(j),regions(r));
        est=H*beta;se=sqrt(H*m.CoefficientCovariance*H');
        [p,~,~,df]=coefTest(m,H,0,'DFMethod','satterthwaite');
        assert(isfinite(p)&&p>=0&&p<=1&&isfinite(df)&&df>0, ...
            'CCPublic:RegionalInference','Invalid regional inference.');
        d=tinv(.975,df)*se;
        rows(end+1,:)={regions(r),late(j)+" minus "+early(j),est,se,df,p,est-d,est+d}; %#ok<AGROW>
    end
end
Q=cell2table(rows,'VariableNames',{'Region','Contrast','Estimate','SE','DF', ...
    'P_Unadjusted','CI_Lower','CI_Upper'});
[p,order]=sort(Q.P_Unadjusted);mTests=numel(p);
a=min(1,cummax((mTests:-1:1)'.*p));
Q.P_Holm=nan(mTests,1);Q.P_Holm(order)=a;
end
function H=stateVector(names,state,region)
H=zeros(1,numel(names));
if state=="Pre",return;end
term="State_"+state;
i=find(names==term);assert(numel(i)==1,'CCPublic:RegionalTerm','State term absent.');H(i)=1;
if region~="CP"
    term2="Region_"+region;
    i=find(names==term+":"+term2 | names==term2+":"+term);
    assert(numel(i)==1,'CCPublic:RegionalTerm','State-region term absent.');H(i)=1;
end
end
