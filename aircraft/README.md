# fg-aircraft

Flightgear aircraft models for F-14 and F-15 by Richard Harrison

- F-14 - see http://zaretto.com/f-14. JSBSim aero model and improvements to original f-14b by xii, flying_toaster;
- F-15 - C and D variants. http://zaretto.com/f-15. JSBSim aero model, external model by flying_toaster; cockpit photo textures by geneb.


# Zaretto FlightGear Aircraft Models

Flightgear aircraft models by Richard Harrison.

F-14 
- https://github.com/Zaretto/f-14b.git 
- F-14 A and B variants. see http://zaretto.com/f-14. JSBSim aero model and improvements to original f-14b by xii, flying_toaster;
- Issues: https://github.com/Zaretto/f-14b/issues

F-15
- https://github.com/Zaretto/F-15.git  
- C and D variants. http://zaretto.com/f-15. JSBSim aero model, external model by flying_toaster; cockpit photo textures by geneb.
- Issues: https://github.com/Zaretto/F-15/issues

## NOTES

- Changed to using submodules on 14/06/2025

## Working with submodules

When cloning for the first time, use the --recursive flag so that Git initializes and updates all the submodules automatically: `git clone --recursive https://github.com/Zaretto/new-aircraft.git`. If already checked out then `git submodule update --init --recursive`

To pull changes from the remote repository—including updates within submodules `git pull --recurse-submodules`. To ensure all submodules are synchronized `git submodule update --init --recursive`


You can check the state and commit of each submodule with: `git submodule status`

## Branches 

Using GitFlow 

* master is for releases
* develop is for the next version
* feature/name is for individual features
* release/#.## is for an upcoming release.

## Contributing 

Contributions are encouraged; I prefer that pull requests are related to an issue but a good explanation in the PR works equally well.

Ideal workflow
- communicate by raising an issue
- contribute by making the changes to the master branch, test and then when you're happy generate a pull request
- wait for the pull request to be reviewed and accepted. 

