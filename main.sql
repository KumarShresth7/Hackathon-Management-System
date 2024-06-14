-- Create Tables

CREATE TABLE Member(
    id number PRIMARY KEY,
    name varchar(100),
    email varchar(100)
);

CREATE TABLE Team(
    id number PRIMARY KEY,
    team_name varchar(100),
    marks number,
    member1_id number,
    member2_id number,
    member3_id number,
    member4_id number,
    FOREIGN KEY (member1_id) REFERENCES Member(id),
    FOREIGN KEY (member2_id) REFERENCES Member(id),
    FOREIGN KEY (member3_id) REFERENCES Member(id),
    FOREIGN KEY (member4_id) REFERENCES Member(id)
);

CREATE TABLE Judge(
    id number PRIMARY KEY,
    name varchar(100),
    email varchar(100)
);


INSERT INTO Judge VALUES(1, 'Prof. Sachin Kansal', 'skansal@thapar.edu');
INSERT INTO Judge VALUES(2, 'Prof. Prashant singh rana', 'psrana@thapar.edu');
INSERT INTO Judge VALUES(3, 'Dr. Rajendra Kumar Roul', 'rkumarroul@thapar.edu');
SELECT * FROM Judge;

CREATE TABLE Project(
    id number PRIMARY KEY,
    name varchar(100),
    description varchar(100),
    team_id number UNIQUE,
    submission_time timestamp,
    FOREIGN KEY (team_id) REFERENCES Team(id)
);

CREATE TABLE Judges(
    project_id number,
    judge_id number,
    FOREIGN KEY (judge_id) REFERENCES Judge(id),
    FOREIGN KEY (project_id) REFERENCES Project(id)
);

CREATE TABLE Admin(
    id number PRIMARY KEY,
    username varchar(100),
    password varchar(100)
);



-- Add entries
INSERT INTO Member Values(1, 'Aishwarya Jain', 'ajain_be22@thapar.edu');
INSERT INTO Member Values(2, 'Muskan Kumari', 'mkumari1_be22@thapar.edu');
INSERT INTO Member Values(3, 'Abhinandan Wadhwa', 'abhinandanwadhwa5@gmail.com');
INSERT INTO Member Values(4, 'Kumar Shresth', 'kshresth_be22@thapar.edu');

SELECT * FROM Member;

-- Procedures
-- 1. Procedure for registering a member
CREATE OR REPLACE PROCEDURE register_member(
    new_name IN VARCHAR2,
    new_email IN VARCHAR2
) IS
    new_id NUMBER;
    existing_email_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO existing_email_count
    FROM Member
    WHERE email = new_email;

    IF existing_email_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Error: Email address already exists.');
		RETURN;
    END IF;


    SELECT NVL(MAX(id), 0) + 1 INTO new_id FROM Member;

    INSERT INTO Member VALUES (new_id, new_name, new_email);
    DBMS_OUTPUT.PUT_LINE('New member registered successfully with ID: ' || new_id);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error registering member: ' || SQLERRM);
END;

execute register_member('Devik Raghuvanshi', 'devikraghu@gmail.com');
execute register_member('Gopal Agarwal', 'gopal.ag0224@gmail.com');
execute register_member('Shivansh Tuteja', 'stuteja@gmail.com');
execute register_member('Pranjal Kishor', 'pkishor@gmail.com');
SELECT * FROM Member;
DELETE FROM Member WHERE id IN(5, 6);


-- 2. Procedure for creating a team
CREATE OR REPLACE PROCEDURE create_team(
    member1_id IN number,
    member2_id IN number,
    member3_id IN number,
    member4_id IN number,
    team_name IN varchar2
) IS
    next_team_id number;
    existing_member_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO existing_member_count
    FROM (
        SELECT member1_id AS member_id FROM Team
        UNION ALL
        SELECT member2_id FROM Team
        UNION ALL
        SELECT member3_id FROM Team
        UNION ALL
        SELECT member4_id FROM Team
    )
    WHERE member_id IN (member1_id, member2_id, member3_id, member4_id);

    IF existing_member_count > 0 THEN
        DBMS_OUTPUT.PUT_LINE('Error: One or more members are already assigned to existing teams.');
        RETURN;
    END IF;
    
    SELECT NVL(MAX(id), 0) + 1 INTO next_team_id FROM Team;
	DBMS_OUTPUT.PUT_LINE('New Team ID: ' || next_team_id);

	INSERT INTO Team VALUES (next_team_id, team_name, NULL, member1_id, member2_id, member3_id, member4_id);
	DBMS_OUTPUT.PUT_LINE('Team "' || team_name || '" created successfully!');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error creating team: ' || SQLERRM);
END;

execute create_team(1, 2, 3, 4, 'incognito');
execute create_team(5, 6, 7, 8, 'KKK');
SELECT * FROM Team;


-- 3. Procedure for submitting a project
CREATE OR REPLACE PROCEDURE submit_project(
    project_name IN VARCHAR2,
    project_description IN VARCHAR2,
    project_team_id IN NUMBER,
    project_submission_time IN TIMESTAMP
) IS
    new_project_id NUMBER;
    existing_project_count NUMBER;
    selected_judge_id NUMBER;
BEGIN
    SELECT COUNT(*) INTO existing_project_count
    FROM Project
    WHERE team_id = project_team_id;

    IF existing_project_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Error: The team has already submitted a project.');
        RETURN;
    END IF;

    SELECT NVL(MAX(id), 0) + 1 INTO new_project_id FROM Project;

    INSERT INTO Project (id, name, description, team_id, submission_time)
    VALUES (new_project_id, project_name, project_description, project_team_id, project_submission_time);

    DBMS_OUTPUT.PUT_LINE('Project submitted successfully with ID: ' || new_project_id);

    SELECT id INTO selected_judge_id
    FROM (
        SELECT id
        FROM Judge
        ORDER BY DBMS_RANDOM.VALUE
    )
    WHERE ROWNUM = 1;

    INSERT INTO Judges (judge_id, project_id) VALUES (selected_judge_id, new_project_id);

    DBMS_OUTPUT.PUT_LINE('Judge ID ' || selected_judge_id || ' assigned to project ID ' || new_project_id);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error submitting project: ' || SQLERRM);
END;

execute submit_project('sentinal ai', 'Surveillance cameras able enough to detect any lost bags and trace it’s original owners.', 1, SYSTIMESTAMP);
execute submit_project('safety synv', 'Supervision helmets for construction workers.', 2, SYSTIMESTAMP);
SELECT * FROM Project;
SELECT * FROM Judges;



-- 4. Function for authentication
CREATE OR REPLACE FUNCTION authenticate_admin(
    p_username IN VARCHAR2,
    p_password IN VARCHAR2
) RETURN BOOLEAN IS
    stored_password VARCHAR2(2000);
    entered_password_hash VARCHAR2(2000);
    is_authenticated BOOLEAN := FALSE;
BEGIN
    SELECT password INTO stored_password
    FROM Admin
    WHERE username = p_username;

    entered_password_hash := RAWTOHEX(DBMS_CRYPTO.HASH(UTL_RAW.CAST_TO_RAW(p_password), DBMS_CRYPTO.HASH_SH256));

    IF stored_password = entered_password_hash THEN
        is_authenticated := TRUE;
    END IF;

    RETURN is_authenticated;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN FALSE;
    WHEN OTHERS THEN
        RETURN FALSE;
END;

DECLARE
    is_authenticated BOOLEAN;
BEGIN
    is_authenticated := authenticate_admin('admin', 'admin@123');
    IF is_authenticated THEN
        DBMS_OUTPUT.PUT_LINE('Authentication successful.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Authentication failed.');
    END IF;
END;





-- 5. Procedure for marking teams
CREATE OR REPLACE PROCEDURE update_team_marks(
    p_team_id NUMBER,
    p_innovation_score NUMBER,
    p_technical_score NUMBER,
    p_impact_score NUMBER,
    p_presentation_score NUMBER
) IS
    v_total_score NUMBER;
BEGIN
    v_total_score := (0.8*p_innovation_score + 0.7* p_technical_score + 0.5*p_impact_score + 0.2*p_presentation_score) / 4;
    UPDATE Team
    SET marks = v_total_score
    WHERE id = p_team_id;

    DBMS_OUTPUT.PUT_LINE('Marks updated successfully for Team ID: ' || p_team_id);
EXCEPTION
    WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error updating marks: ' || SQLERRM);
END;

EXECUTE update_team_marks(1, 85, 90, 88, 92);
EXECUTE update_team_marks(2, 92, 95, 81, 89);
SELECT * FROM TEAM;


-- 6. Admin controls
CREATE OR REPLACE PROCEDURE admin_panel(
    username IN VARCHAR2,
    password IN VARCHAR2,
    choice IN VARCHAR2
) AS
    is_admin BOOLEAN;
BEGIN
    is_admin := authenticate_admin(username, password);

    -- Check if the user is an admin
    IF is_admin THEN
        CASE choice
            WHEN 1 THEN
                DBMS_OUTPUT.PUT_LINE('User Management functionality not implemented yet.');
            WHEN 2 THEN
                DBMS_OUTPUT.PUT_LINE('Team Management functionality not implemented yet.');
            WHEN 3 THEN
                DBMS_OUTPUT.PUT_LINE('Project Evaluation functionality not implemented yet.');
            WHEN 4 THEN
                DBMS_OUTPUT.PUT_LINE('System Administration functionality not implemented yet.');
            ELSE
                DBMS_OUTPUT.PUT_LINE('Invalid choice. Please select a valid option.');
        END CASE;
    ELSE
        DBMS_OUTPUT.PUT_LINE('Access denied. You are not authorized to access the admin panel.');
    END IF;
END;

execute admin_panel('admin', 'admin@123', 2);


-- 7. Generate Leaderboard
CREATE OR REPLACE FUNCTION generate_leaderboard
RETURN SYS_REFCURSOR IS
    leaderboard_cursor SYS_REFCURSOR;
BEGIN
    OPEN leaderboard_cursor FOR
        SELECT team_name, marks
        FROM Team
        ORDER BY marks DESC;
    RETURN leaderboard_cursor;
END generate_leaderboard;


DECLARE
    leaderboard_cursor SYS_REFCURSOR;
    team_name VARCHAR2(100);
    marks NUMBER;
BEGIN
    leaderboard_cursor := generate_leaderboard();
    
    LOOP
        FETCH leaderboard_cursor INTO team_name, marks;
        EXIT WHEN leaderboard_cursor%NOTFOUND;
        
        DBMS_OUTPUT.PUT_LINE('Team: ' || team_name || ', Marks: ' || marks);
    END LOOP;
    
    CLOSE leaderboard_cursor;
END;


-- Trigger for hashing password that fires before an insert operation on the table
CREATE OR REPLACE TRIGGER hash_password_trigger
BEFORE INSERT ON Admin
FOR EACH ROW
DECLARE
    hashed_password RAW(2000);
BEGIN
    hashed_password := DBMS_CRYPTO.HASH(UTL_RAW.CAST_TO_RAW(:NEW.password), DBMS_CRYPTO.HASH_SH256);
    
    :NEW.password := RAWTOHEX(hashed_password);
END;

INSERT INTO Admin VALUES(1, 'admin', 'admin@123');
SELECT * FROM Admin;











CREATE OR REPLACE PROCEDURE create_admin(
    p_username IN VARCHAR2,
    p_password IN VARCHAR2
) IS
    new_id Number;
BEGIN
    SELECT NVL(MAX(id), 0) + 1 INTO new_id FROM Admin;

    INSERT INTO Admin VALUES (new_id, p_username, p_password);
    DBMS_OUTPUT.PUT_LINE('Admin created successfully.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error creating admin: ' || SQLERRM);
END;


execute create_admin('musu', 'musu@123');

SELECT * FROM Admin;
