# clamav 
Clamav configuration and 

- "clamd.conf" and "freshclam.conf" are templates of configuration files of the Clamav Scanner Antivirus. 
- "clamscan.ps1" its an Powershell script file that can help to enable some tasks automatization, like:
  - Create a Scheduled Task at windows.
  - Update the Database
  - Scanning for Virus at "C:users\"

Some steps are needed to make a good work:

1.  You need to install the Clamav using the GPO (Group Policy Object) of the AD (Active Directory):
  Example:
  ![ad-install-clamav-msi](https://github.com/user-attachments/assets/97a8e3cb-c737-454a-ae8c-d1c65e31b289)


2. Using the Active Directory at the Windows Server, you will send the config files and create the folders, to run Clamav.
  
  To do this may you need to create another GPO:
  ![image](https://github.com/user-attachments/assets/89e484d5-8071-47d1-a59e-60d82bc1bc9a)

Now you can send the "clamd.conf" and "freshclam.conf" files to every endpoint at network.

  ![AD-FILES](https://github.com/user-attachments/assets/67182589-1c39-4162-bef0-d92dda4a266b)

 These Files are examples of the use of Clamav, you can change them at will. Feel free to make changes and some personalizations.
   
3. The Powershell must to execute at the startup of the machines to do automatizated scannings on many endpoints possible,
  To do this you need to make this configuration in the GPO at the AD:

![powershell-clamav](https://github.com/user-attachments/assets/43e89685-c1d9-43f8-b13c-4baa19c4c2fe)


# Summary of Functionalities of the ".ps1":
- Take off the execution restriction policy of scripts powershell;
- Updates virus definitions (using freshclam).
- Performs a scan (clamscan) on a specified directory (default: C:\Users).
- Logs the results to a file (clamscan.log).
- Create the Task Scheduled to make some scans every startup + some hours (you can adjust at will)
- Turn on the execution restriction policy of scripts powershell;
