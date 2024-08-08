-- Create categories table
CREATE TABLE IF NOT EXISTS categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL
);

-- Insert top 5 job categories
INSERT INTO categories (name) VALUES
    ('Software Engineering'),
    ('Data Science'),
    ('Product Management'),
    ('Design'),
    ('Marketing');

-- Create subcategories table
CREATE TABLE IF NOT EXISTS subcategories (
    id SERIAL PRIMARY KEY,
    category_id INT REFERENCES categories(id),
    name VARCHAR(50) NOT NULL
);

-- Insert subcategories for each category
-- Software Engineering
INSERT INTO subcategories (category_id, name) VALUES
    ((SELECT id FROM categories WHERE name = 'Software Engineering'), 'Backend Developer'),
    ((SELECT id FROM categories WHERE name = 'Software Engineering'), 'Frontend Developer'),
    ((SELECT id FROM categories WHERE name = 'Software Engineering'), 'Full Stack Developer'),
    ((SELECT id FROM categories WHERE name = 'Software Engineering'), 'DevOps Engineer'),
    ((SELECT id FROM categories WHERE name = 'Software Engineering'), 'Software Architect');

-- Data Science
INSERT INTO subcategories (category_id, name) VALUES
    ((SELECT id FROM categories WHERE name = 'Data Science'), 'Data Analyst'),
    ((SELECT id FROM categories WHERE name = 'Data Science'), 'Data Scientist'),
    ((SELECT id FROM categories WHERE name = 'Data Science'), 'Machine Learning Engineer'),
    ((SELECT id FROM categories WHERE name = 'Data Science'), 'Data Engineer'),
    ((SELECT id FROM categories WHERE name = 'Data Science'), 'Business Intelligence Analyst');

-- Product Management
INSERT INTO subcategories (category_id, name) VALUES
    ((SELECT id FROM categories WHERE name = 'Product Management'), 'Product Manager'),
    ((SELECT id FROM categories WHERE name = 'Product Management'), 'Product Owner'),
    ((SELECT id FROM categories WHERE name = 'Product Management'), 'Project Manager'),
    ((SELECT id FROM categories WHERE name = 'Product Management'), 'Product Marketing Manager'),
    ((SELECT id FROM categories WHERE name = 'Product Management'), 'Technical Product Manager');

-- Design
INSERT INTO subcategories (category_id, name) VALUES
    ((SELECT id FROM categories WHERE name = 'Design'), 'UI/UX Designer'),
    ((SELECT id FROM categories WHERE name = 'Design'), 'Graphic Designer'),
    ((SELECT id FROM categories WHERE name = 'Design'), 'Product Designer'),
    ((SELECT id FROM categories WHERE name = 'Design'), 'Interaction Designer'),
    ((SELECT id FROM categories WHERE name = 'Design'), 'Visual Designer');

-- Marketing
INSERT INTO subcategories (category_id, name) VALUES
    ((SELECT id FROM categories WHERE name = 'Marketing'), 'Digital Marketer'),
    ((SELECT id FROM categories WHERE name = 'Marketing'), 'SEO Specialist'),
    ((SELECT id FROM categories WHERE name = 'Marketing'), 'Content Marketer'),
    ((SELECT id FROM categories WHERE name = 'Marketing'), 'Marketing Manager'),
    ((SELECT id FROM categories WHERE name = 'Marketing'), 'Growth Hacker');
-- Create cities table
CREATE TABLE IF NOT EXISTS cities (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    state VARCHAR(50) NOT NULL
);

-- Insert cities in India
INSERT INTO cities (name, state) VALUES
    ('Mumbai', 'Maharashtra'),
    ('Delhi', 'Delhi'),
    ('Bangalore', 'Karnataka'),
    ('Hyderabad', 'Telangana'),
    ('Chennai', 'Tamil Nadu'),
    ('Pune', 'Maharashtra'),
    ('Kolkata', 'West Bengal'),
    ('Ahmedabad', 'Gujarat'),
    ('Jaipur', 'Rajasthan'),
    ('Chandigarh', 'Chandigarh');

-- Create job_vacancies table
CREATE TABLE IF NOT EXISTS job_vacancies (
    id UUID DEFAULT uuid_generate_v4 (),
    category_id INT REFERENCES categories(id),
    subcategory_id INT REFERENCES subcategories(id),
    city_id INT REFERENCES cities(id),
    job_title VARCHAR(100),
    company VARCHAR(100),
    salary DECIMAL(10, 2),
    posted_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);

-- Create salary ranges table
CREATE TABLE IF NOT EXISTS salary_ranges (
    job_title VARCHAR(50) PRIMARY KEY,
    min_salary DECIMAL(10, 2),
    max_salary DECIMAL(10, 2)
);

-- Insert sample salary ranges
INSERT INTO salary_ranges (job_title, min_salary, max_salary) VALUES
    ('Backend Developer', 50000, 120000),
    ('Frontend Developer', 45000, 110000),
    ('Full Stack Developer', 55000, 130000),
    ('DevOps Engineer', 60000, 140000),
    ('Software Architect', 70000, 160000),
    ('Data Analyst', 40000, 90000),
    ('Data Scientist', 50000, 110000),
    ('Machine Learning Engineer', 60000, 120000),
    ('Data Engineer', 55000, 115000),
    ('Business Intelligence Analyst', 45000, 100000),
    ('Product Manager', 60000, 150000),
    ('Product Owner', 55000, 140000),
    ('Project Manager', 50000, 130000),
    ('Product Marketing Manager', 55000, 125000),
    ('Technical Product Manager', 65000, 140000),
    ('UI/UX Designer', 40000, 90000),
    ('Graphic Designer', 35000, 80000),
    ('Product Designer', 45000, 95000),
    ('Interaction Designer', 40000, 85000),
    ('Visual Designer', 37000, 80000),
    ('Digital Marketer', 35000, 85000),
    ('SEO Specialist', 30000, 75000),
    ('Content Marketer', 32000, 70000),
    ('Marketing Manager', 40000, 95000),
    ('Growth Hacker', 35000, 80000);

-- Create city salary multipliers table
CREATE TABLE IF NOT EXISTS city_salary_multipliers (
    city_name VARCHAR(50) PRIMARY KEY,
    multiplier DECIMAL(5, 2)
);

-- Insert sample city salary multipliers
INSERT INTO city_salary_multipliers (city_name, multiplier) VALUES
    ('Mumbai', 1.20),
    ('Delhi', 1.15),
    ('Bangalore', 1.30),
    ('Hyderabad', 1.10),
    ('Chennai', 1.05),
    ('Pune', 1.10),
    ('Kolkata', 1.00),
    ('Ahmedabad', 1.05),
    ('Jaipur', 0.95),
    ('Chandigarh', 1.00);




CREATE OR REPLACE FUNCTION insert_job_vacancies_batch(batch_size INT, total_records INT)
RETURNS VOID AS $$
DECLARE
    start_index INT := 1;
    end_index INT;
BEGIN
    WHILE start_index <= total_records LOOP
        end_index := start_index + batch_size - 1;
        IF end_index > total_records THEN
            end_index := total_records;
        END IF;
        
        INSERT INTO job_vacancies (category_id, subcategory_id, city_id, job_title, company, salary, posted_date)
        WITH generated_data AS (
            SELECT
                cat.id AS category_id,
                sub.id AS subcategory_id,
                city.id AS city_id,
                CONCAT(sub.name, ' - ', city.name) AS job_title,
                CONCAT('Company ', (random() * 1000)::INT) AS company,
                COALESCE(sr.min_salary, 30000) + (random() * (COALESCE(sr.max_salary, 200000) - COALESCE(sr.min_salary, 30000))) * COALESCE(csm.multiplier, 1.00) AS salary,
                NOW() - INTERVAL '1 day' * (random() * 30) AS posted_date
            FROM generate_series(start_index, end_index) AS s
            CROSS JOIN categories cat
            JOIN subcategories sub ON sub.category_id = cat.id
            CROSS JOIN cities city
            LEFT JOIN salary_ranges sr ON sub.name = sr.job_title
            LEFT JOIN city_salary_multipliers csm ON city.name = csm.city_name
        )
        SELECT
            gd.category_id,
            gd.subcategory_id,
            gd.city_id,
            gd.job_title,
            gd.company,
            gd.salary,
            gd.posted_date
        FROM generated_data gd;
        
        start_index := end_index + 1;
    END LOOP;
END;
$$ LANGUAGE plpgsql;


SELECT insert_job_vacancies_batch(1000, 5000);