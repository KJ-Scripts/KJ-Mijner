INSERT INTO `items` (`name`, `label`, `weight`, `rare`, `can_remove`) VALUES
('steen', 'Steen', 1, 0, 1),
('steenkool', 'Steenkool', 1, 0, 1),
('houtskool', 'Houtskool', 1, 0, 1),
('ijzer', 'Ijzer', 1, 0, 1),
('brons', 'Brons', 1, 0, 1),
('zilver', 'Zilver', 1, 0, 1),
('smaragd', 'Smaragd', 1, 0, 1),
('goud', 'Goud', 1, 0, 1),
('diamant', 'Diamant', 1, 0, 1),
('pikhouweel', 'Pikhouweel', 1, 0, 1);

INSERT INTO `jobs` (`name`, `label`, `whitelisted`) VALUES
('mijner', 'Mijnwerker', 0);

INSERT INTO `job_grades` (`id`, `job_name`, `grade`, `name`, `label`, `salary`, `skin_male`, `skin_female`) VALUES
(1, 'mijner', 0, 'Mijnwerker', 'Mijnwerker', 500, '{"tshirt_2":1,"ears_1":8,"glasses_1":15,"torso_2":0,"ears_2":2,"glasses_2":3,"shoes_2":1,"pants_1":75,"shoes_1":51,"bags_1":0,"helmet_2":0,"pants_2":7,"torso_1":71,"tshirt_1":59,"arms":2,"bags_2":0,"helmet_1":0}', '{}');