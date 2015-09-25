\connect c3;
SET search_path TO api;

INSERT INTO owner_parents VALUES (DEFAULT, 'user'),
       	    		  	 (DEFAULT, 'user'),
				 (DEFAULT, 'org');

INSERT INTO users (id, username, password, first_name, last_name, email, is_admin, is_active) VALUES
       	    	  (1, 'admin','*4ACFE3202A5FF5CF467898FC58AAB1D615029441', 'C3 DEMO', 'Administrator', 'nock@nocko.se', TRUE, TRUE),
		  (2, 'slee', '*4ACFE3202A5FF5CF467898FC58AAB1D615029441', 'Soo-Yeong', 'Lee', 'slee@fakenet.com', FALSE, TRUE);

INSERT INTO orgs (id, name, uuid) VALUES (3, 'Shulman and Associates', '1b47b8c9d30d4af8a8c3e3876f69eac5');

INSERT INTO users_orgs (id, user_id, org_id, permissions) VALUES (DEFAULT, 2, 3, 'MANAGE');

INSERT INTO beacon_groups VALUES (DEFAULT,'Doctors','Physicians and Surgeons', NULL, 3),
			         (DEFAULT,'Patients','', NULL, 3),
			         (DEFAULT,'Admin Staff','All non-physician staff', NULL, 3),
			         (DEFAULT,'Equipment','', NULL, 3);

INSERT INTO event_parents values (DEFAULT, 'beacon'),
       	    		  	 (DEFAULT, 'beacon'),
				 (DEFAULT, 'beacon'),
				 (DEFAULT, 'beacon'),
				 (DEFAULT, 'beacon'),
				 (DEFAULT, 'beacon'),
				 (DEFAULT, 'zone'),
				 (DEFAULT, 'zone'),
				 (DEFAULT, 'zone'),
				 (DEFAULT, 'zone'),
				 (DEFAULT, 'zone'),
				 (DEFAULT, 'zone'),
				 (DEFAULT, 'zone'),
				 (DEFAULT, 'listener'),
				 (DEFAULT, 'listener'),
				 (DEFAULT, 'listener'),
				 (DEFAULT, 'listener'),
				 (DEFAULT, 'listener'),
				 (DEFAULT, 'listener'),
				 (DEFAULT, 'listener'),
				 (DEFAULT, 'listener');

INSERT INTO beacons VALUES
  (1,'','Scott White',NULL,NULL,3,0,0,'Receptionist',NULL,NULL,'6a4f50cb-091a-4c88-abad-5f83a362471f',-60,NULL,3),
  (2,'','Imari Jackson',NULL,NULL,1,0,1,'Surgeon',NULL,NULL, '6a4f50cb-091a-4c88-abad-5f83a362471f',-60,NULL,3),
  (3,'','Lee Soo-Yeon',NULL,NULL,1,0,2,'Anesthesiologist',NULL,NULL,'6a4f50cb-091a-4c88-abad-5f83a362471f',-60,NULL,3),
  (4,'','Patient #7483',NULL,NULL,2,0,3,'Deidentified Patient',NULL,NULL,'6a4f50cb-091a-4c88-abad-5f83a362471f',-60,NULL,3),
  (5,'','Patient #2340',NULL,NULL,2,0,4,'Deidentified Patient',NULL,NULL,'6a4f50cb-091a-4c88-abad-5f83a362471f',-60,NULL,3),
  (6,'','Gurney #1',NULL,NULL,4,0,5,'Transport gurney',NULL,NULL,'6a4f50cb-091a-4c88-abad-5f83a362471f',-60,NULL,3);

INSERT INTO zones VALUES
       (7,'Dr. Jackson''s Office','72,73,74,75,76,101,102,103,104,105,130,131,132,133,134,159,160,161,162,163','#ef0a0a',3),
       (8,'Dr. Lee''s Office','68,69,70,71,97,98,99,100,126,127,128,129,155,156,157,158','#efe613',3),
       (9,'Surgery','765,766,767,768,769,770,771,772,794,795,796,797,798,799,800,801,823,824,825,826,827,828,829,830,852,853,854,855,856,857,858,859,881,882,883,884,885,886,887,888,910,911,912,913,914,915,916,917,939,940,941,942,943,944,945,946,968,969,970,971,972,973,974,975,997,998,999,1000,1001,1002,1003,1004,1027,1028,1058,1059,1089,1090,1120,1091,1062,1033,1032,1061,1060,1031,1030,1029','#fcc710',3),
       (10,'Recovery Room','756,757,758,759,760,761,762,763,764,785,786,787,788,789,790,791,792,793,814,815,816,817,818,819,820,821,822,843,844,845,846,847,848,849,850,851,872,873,874,875,876,877,878,879,880,903,904,905,906,907,908,909,934,935,936,937,938,965,966,967,996','#17e0ee',3),
       (11,'Washrooms','776,777,778,779,805,806,807,808,834,835,836,837,863,864,865,866,892,893,894,895,921,922,923,924,950,951,952,953','#5d1111',3),
       (12,'Lobby','247,248,249,250,251,252,253,254,255,276,277,278,279,280,281,282,283,284,305,306,307,308,309,310,311,312,313,334,335,336,337,338,339,340,341,342,363,364,365,366,367,368,369,370,371,392,393,394,395,396,397,398,399,400,421,422,423,424,425,426,427,428,429,450,451,452,453,454,455,456,457,458,479,480,481,482,483,484,485,486,487,508,509,510,511,512,513,514,515,516,537,538,539,540,541,542,543,544,545,566,567,568,569,570,571,572,573,574,595,596,597,598,599,600,601,602,603,624,625,626,627,628,629,630,631,632,653,654,655,656,657,658,659,660,661,682,683,684,685,686,687,688,689,690','#2138d5',3),
       (13,'Equipment Storage','294,295,296,297,298,299,323,324,325,326,327,328,352,353,354,355,356,357,381,382,383,384,385,386,410,411,412,413,414,415,439,440,441,442,443,444,468,469,470,471,472,473','#32f01b',3);

INSERT INTO listeners VALUES
  (14,'','Lobby','40cc397a-29a2-4c2c-9dbd-83da0f7b93d6','',258.071207430341,540.121985090037,12,3),
  (15,'','Dr. Jackson''s Office','d53ed36f-6c7d-4ab1-a909-3b7ecbf05893','',148.758513931889,493.273687876415,7,3),
  (16,'','Dr. Lee''s Office','99aefcbd-d0a0-499e-9e9d-760b32c2c01a','',153.56346749226,359.936226576105,8,3),
  (17,'','Recovery Room #1','d9d96070-fa45-4700-9368-6c89bcb74705','',827.458204334365,218.190096545146,10,3),
  (18,'','Recovery Room #2','2e8eb88b-bde7-4eb2-bca9-8b547b5a0528','',751.780185758514,100.468734316043,10,3),
  (19,'','Surgery','acadc6c5-cdc8-4213-b8cf-81fbe9a16a5e','',974.009287925697,406.784523789728,9,3),
  (20,'','Storage Room','107c8b7a-6d05-4747-b29f-ee95eaf0c634','',403.421052631579,183.354183232452,13,3),
  (21,'','Washroom','a7975000-4ab8-4528-93c9-e2da4ec1cb27','',852.684210526316,613.397526885703,11,3);

