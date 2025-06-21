create database Online_Resume;
use Online_Resume;

-- USERS TABLE
CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- RESUME TEMPLATES
CREATE TABLE templates (
    template_id INT AUTO_INCREMENT PRIMARY KEY,
    template_name VARCHAR(100) NOT NULL,
    description TEXT,
    layout_config JSON, -- Optional structure config
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- RESUMES
CREATE TABLE user_resumes (
    resume_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    template_id INT,
    resume_name VARCHAR(100),
    resume_version INT DEFAULT 1,
    is_latest BOOLEAN DEFAULT TRUE,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (template_id) REFERENCES templates(template_id)
);

-- SECTION TYPES (Education, Experience, Skills, etc.)
CREATE TABLE sections (
    section_id INT AUTO_INCREMENT PRIMARY KEY,
    section_name VARCHAR(100) NOT NULL
);

-- LINK TEMPLATE TO SECTIONS
CREATE TABLE template_sections (
    template_id INT,
    section_id INT,
    section_order INT,
    PRIMARY KEY (template_id, section_id),
    FOREIGN KEY (template_id) REFERENCES templates(template_id),
    FOREIGN KEY (section_id) REFERENCES sections(section_id)
);

-- USER RESUME SECTIONS (custom ordering/editing)
CREATE TABLE user_resume_sections (
    urs_id INT AUTO_INCREMENT PRIMARY KEY,
    resume_id INT,
    section_id INT,
    section_order INT,
    is_visible BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (resume_id) REFERENCES user_resumes(resume_id),
    FOREIGN KEY (section_id) REFERENCES sections(section_id)
);

-- SECTION DATA (User input per section)
CREATE TABLE section_data (
    data_id INT AUTO_INCREMENT PRIMARY KEY,
    resume_id INT,
    section_id INT,
    field_label VARCHAR(100),
    field_value TEXT,
    field_order INT,
    FOREIGN KEY (resume_id) REFERENCES user_resumes(resume_id),
    FOREIGN KEY (section_id) REFERENCES sections(section_id)
);

-- AUDIT LOGS
CREATE TABLE audit_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    action VARCHAR(100),
    entity_type VARCHAR(50),
    entity_id INT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    details TEXT,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- Insert Users
INSERT INTO users (full_name, email, password_hash) VALUES
('Sita Ram', 'ramsita@example.com', 'Ram@123'),
('Mohan lal', 'mohan@example.com', 'Mohan@123');

-- Insert Templates
INSERT INTO templates (template_name, description) VALUES
('Classic', 'A traditional resume layout.'),
('Modern', 'A modern, clean resume format.');

-- Insert Sections
INSERT INTO sections (section_name) VALUES
('Education'), ('Experience'), ('Skills');


-- Assign Sections to Templates
INSERT INTO template_sections (template_id, section_id, section_order) VALUES
(1, 1, 1), (1, 2, 2), (1, 3, 3),
(2, 2, 1), (2, 3, 2), (2, 1, 3);

-- Create User Resume
INSERT INTO user_resumes (user_id, template_id, resume_name) VALUES
(1, 1, 'Ram Resume v1');

-- Link Sections to Resume
INSERT INTO user_resume_sections (resume_id, section_id, section_order) VALUES
(1, 1, 1), (1, 2, 2), (1, 3, 3);


-- Add Section Data
INSERT INTO section_data (resume_id, section_id, field_label, field_value, field_order) VALUES
(1, 1, 'Degree', 'Btech in Computer Science', 1),
(1, 1, 'Institution', 'XYZ University', 2),
(1, 2, 'Job Title', 'Software Intern', 1),
(1, 2, 'Company', 'Tech Corp', 2),
(1, 3, 'Skill', 'MySQL', 1),
(1, 3, 'Skill', 'Java', 2);


-- Track Resume Changes
DELIMITER //

CREATE TRIGGER trg_resume_update
AFTER UPDATE ON user_resumes
FOR EACH ROW
BEGIN
  INSERT INTO audit_logs (
    user_id, action, entity_type, entity_id, details
  )
  VALUES (
    OLD.user_id,
    'UPDATE',
    'Resume',
    OLD.resume_id,
    CONCAT('Resume name changed from "', OLD.resume_name, '" to "', NEW.resume_name, '"')
  );
END;
//
DELIMITER ;

-- Delete Trigger
DELIMITER //

CREATE TRIGGER trg_soft_delete_resume
BEFORE DELETE ON user_resumes
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000'
  SET MESSAGE_TEXT = 'Direct DELETE not allowed. Use soft delete (is_deleted).';
END;
//
DELIMITER ;


-- Create New Resume Version
DELIMITER //

CREATE PROCEDURE create_resume_version(IN p_resume_id INT)
BEGIN
  DECLARE original_user INT;
  DECLARE original_template INT;
  DECLARE new_version INT;

  -- Get original data
  SELECT user_id, template_id, resume_version + 1 INTO original_user, original_template, new_version
  FROM user_resumes WHERE resume_id = p_resume_id;

  -- Mark previous as not latest
  UPDATE user_resumes SET is_latest = FALSE WHERE resume_id = p_resume_id;

  -- Duplicate resume
  INSERT INTO user_resumes (user_id, template_id, resume_name, resume_version)
  SELECT user_id, template_id, CONCAT(resume_name, ' v', new_version), new_version
  FROM user_resumes WHERE resume_id = p_resume_id;

  -- You can also duplicate user_resume_sections and section_data using last_insert_id() if needed
END //

DELIMITER ;


 -- Export-Ready Resume (Simulated PDF)
 CREATE VIEW view_resume_export AS
SELECT
    u.full_name,
    r.resume_name,
    s.section_name,
    d.field_label,
    d.field_value,
    d.field_order
FROM section_data d
JOIN sections s ON d.section_id = s.section_id
JOIN user_resumes r ON d.resume_id = r.resume_id
JOIN users u ON r.user_id = u.user_id
WHERE r.is_deleted = FALSE
ORDER BY r.resume_id, s.section_name, d.field_order;
