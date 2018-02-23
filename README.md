# phishme

This project showcases some work with Terraform and building an infrastructure to support Redmine http://www.redmine.org/. 

# Directories

/redmine-baseline  

This has the initial working stack from the template code supplied.  Nothing fancy just an operational version of the Redmine docker container
    
    - meets objective #1
        _Modify, complete, and or improve so it works in your own AWS account_

/final-stack

This represents the final stack which addresses objectives #2 and #3

    - Improve security and high availability of the Docker host and application. 
    - Modify the deployment so that RDS replaces the default SQLite_