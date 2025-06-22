Online Resume Builder (MySQL Only)This project is a database-only backend for an Online Resume Builder system, built using MySQL 8.0+. It includes all core features required to support user-generated resumes, multiple templates, versioning, and audit tracking — without any frontend or backend code.

Features :-
User registration & authentication data storage
Multiple resume templates with customizable sections
Section-wise user input storage (Education, Experience, Skills, etc.)
Resume versioning and naming
View-ready resume export structure for PDF generation
Change tracking via audit logs
Soft delete support (no permanent loss of data)

Database Schema Overview :-
`users` – Stores user details
`templates` – Resume layout options
`user_resumes` – Resume metadata and versioning
`sections` – Types of resume content blocks (like Education)
`template_sections` – Sections assigned per template
`user_resume_sections` – Custom section order and visibility
`section_data` – Actual user content per section
`audit_logs` – Tracks changes to resumes for accountability
