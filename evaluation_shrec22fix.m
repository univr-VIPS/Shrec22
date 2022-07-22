clear all;
max_dim_ratio = 2;
min_overlap_ratio = 0.5;

labels = {"ONE"; "TWO"; "THREE"; "FOUR"; "OK"; "MENU"; "LEFT"; "RIGHT"; "CIRCLE"; "V"; "CROSS"; "GRAB"; "PINCH";"DENY";"WAVE";"KNOB";};

A = {}; %line with the original annotations for one sequence looped in the for
R = {}; %line with the submitted result annotations for one sequence looped in the for

A_file = fopen('test_annotations_fixed.txt'); %<<-- Change this file name with the file you want to use as GT 
R_file = fopen('train_l.txt'); %<<-- Change this file name with the file you want evaluate

Raw_Results = [labels,cell(16,1)];
for (i = 1:16) Raw_Results{i,2} = zeros(1,5); end
%Format [label, [total, correct, missed, FP, Delay]]

for line=1:144
    A_line = fgetl(A_file); R_line = fgetl(R_file);   %Fetching one line from both files
    A = split(A_line,';',2); R = split(R_line,';',2); %Splitting along the separator character
    
    for gA = 2:3:size(A,2)-1 %Verifying GT file consistency. The first column in the 2nd cell of each row of Raw_results should be 36
        AA = A(gA:gA+2); %Fetching the single gestures in the annotations sequence
        label_A = AA{1}; start_A = str2double(AA{2}); end_A = str2double(AA{3});
        ind = find([labels{:}] == label_A);
        Raw_Results{ind,2}(1,1) = Raw_Results{ind,2}(1,1)+1; %Increase the count at the relative cell for the total count/check 
    end

    found = false;
    for gR = 2:4:size(R,2)-1
        RR = R(gR:gR+2); %Fetching the single gestures in the results sequence
        for gA = 2:3:size(A,2)-1
            AA = A(gA:gA+2); %Fetching the single gestures in the annotations sequence
            label_A = AA{1}; start_A = str2double(AA{2}); end_A = str2double(AA{3});
            label_R = RR{1}; start_R = str2double(RR{2}); end_R = str2double(RR{3});
            if (found == false)
                if (strcmp(label_A,label_R)) %Check if the label 
                    if (end_R-start_R <= (end_A-start_A)*max_dim_ratio) %Checking if the gesture in the result is within the maximum dimention limits
                        if((min([end_A, end_R])-max([start_A, start_R]))/(end_A-start_A)>= min_overlap_ratio) %Checking if the overlap between the gesture in the result and the annotated one is bigger than the min overlap ratio
                            %In this case it's a correct detection
                            A(gA:gA+2) = [{'-'},{0},{0}]; %We blank the entry out from A to avoid multiple correct detection
                            ind = find([labels{:}] == label_A);
                            Raw_Results{ind,2}(1,2) = Raw_Results{ind,2}(1,2)+1; %Increase the count at the relative cell
                            Raw_Results{ind,2}(1,5) = Raw_Results{ind,2}(1,5)+minus(str2double(R{gR+3}),str2double(R{gR+1})); %We add the delay as the subtraction the third number and the first, to be avaraged later
                            minus(str2double(R{gR+3}),str2double(R{gR+1}));
                            found = true;
                        end
                    end
                end
            end
        end
        if (found == false)
            %We checked all the gestures in the annotations and no match
            %was found so we classify this as FP
            ind = find([labels{:}] == label_R);
            Raw_Results{ind,2}(1,4) = Raw_Results{ind,2}(1,4)+1; %Increase the count at the relative cell
        end

        found = false; %Reset the variable for the next loop

    end
    for gA = 2:3:size(A,2)-1
        %We check which labels in the sequence have not been blanked out
        %we consider those "missed"
        ind = find([labels{:}] == A{gA});
        if (~isempty(ind))
            Raw_Results{ind,2}(1,3) = Raw_Results{ind,2}(1,3)+1; %Increase the count at the relative cell
        end
    end

end

tmp = cell2mat(Raw_Results(1:16,2));
for d = 1:16
    if tmp(d,2) > 0
        tmp(d,5) = tmp(d,5)/tmp(d,2);
    else
        tmp(d,5) = nan;
    end
end

Compact_Results = zeros(17,4); 
Compact_Results(1:16,1) = tmp(1:16,2)./tmp(1:16,1); %Detection Rate(per class) = Correct(per class) / Total (per class)
Compact_Results(17,1) = sum(Compact_Results(1:16,1))/16;
Compact_Results(1:16,2) = tmp(1:16,4)./tmp(1:16,1); %FP Rate(per class) = FP(per class) / Total(per class)
Compact_Results(17,2) = sum(Compact_Results(1:16,2))/16;
Compact_Results(1:16,3) = tmp(1:16,2)./(tmp(1:16,2)+tmp(1:16,3)+tmp(1:16,4));  %Jaccard Index(per class) = Correct(per class) / (Correct(per class) + missed(per class) + FP(per class))
Compact_Results(17,3) = sum(Compact_Results(1:16,3))/16;
Compact_Results(1:16,4) = tmp(1:16,5);%./tmp(1:16,2); %We avarage the delay by the number of gestures for which we recorded a delay
Compact_Results(17,4) = nansum(Compact_Results(1:16,4))/16;
