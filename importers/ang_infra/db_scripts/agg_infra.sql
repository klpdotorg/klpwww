CREATE OR REPLACE function agg_ang_infra(ac_year text) returns void as $$
declare
  ai_metrics text[17];
  ai_group text[17];
  ai_question text[17];
  ai_max integer[17];
  agg_record RECORD;
  begin
      ai_metrics[1]='building';ai_question[1]='4';ai_max[1]=1;ai_group[1]='Basic Infrastructure';
      ai_metrics[2]='space';ai_question[2]='5,6';ai_max[2]=2;ai_group[2]='Basic Infrastructure';
      ai_metrics[3]='walls';ai_question[3]='8';ai_max[3]=1;ai_group[3]='Basic Infrastructure';
      ai_metrics[4]='floor';ai_question[4]='9';ai_max[4]=1;ai_group[4]='Basic Infrastructure';
      ai_metrics[5]='roof';ai_question[5]='10';ai_max[5]=1;ai_group[5]='Basic Infrastructure';
      ai_metrics[6]='water_supply';ai_question[6]='24,25';ai_max[6]=2;ai_group[6]='Basic Infrastructure';
      ai_metrics[7]='waste_basket';ai_question[7]='15,16';ai_max[7]=2;ai_group[7]='Basic Infrastructure';
      ai_metrics[8]='handwash';ai_question[8]='23';ai_max[8]=1;ai_group[8]='Nutrition and Hygiene';
      ai_metrics[9]='meal_served';ai_question[9]='18,19,21';ai_max[9]=3;ai_group[9]='Nutrition and Hygiene';
      ai_metrics[10]='drinking_water';ai_question[10]='27';ai_max[10]=1;ai_group[10]='Nutrition and Hygiene';
      ai_metrics[11]='toilet';ai_question[11]='29';ai_max[11]=1;ai_group[11]='Toilet Facilities';
      ai_metrics[12]='toilet_roof';ai_question[12]='30';ai_max[12]=1;ai_group[12]='Toilet Facilities';
      ai_metrics[13]='toilet_usable';ai_question[13]='31,32,33';ai_max[13]=3;ai_group[13]='Toilet Facilities';
      ai_metrics[14]='blackboard';ai_question[14]='36';ai_max[14]=1;ai_group[14]='Learning Environment';
      ai_metrics[15]='progress';ai_question[15]='43';ai_max[15]=1;ai_group[15]='Learning Environment';
      ai_metrics[16]='akshara_kits';ai_question[16]='69';ai_max[16]=1;ai_group[16]='Learning Environment';
      ai_metrics[17]='bvs';ai_question[17]='54,55,56,58';ai_max[17]=4;ai_group[17]='Community Involvement';

      for i in 1..17
        loop
           for agg_record in select sid, round(100.0 * sum(ans)/ai_max[i]) as perc_total from tb_ai_answers where qid = ANY(string_to_array(ai_question[i],',')::integer[]) and year=ac_year group by sid
           loop
               insert into tb_ang_infra_agg values (agg_record.sid, ai_metrics[i],agg_record.perc_total,ai_group[i],ac_year);
           end loop;
        end loop;
end;
$$ language plpgsql;
