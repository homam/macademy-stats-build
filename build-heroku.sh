cp -rf . ../../macademy-stats-build/
cd ../../macademy-stats-build
rm -rf d3-template/.git
git add .
git commit -am "heroku build"
git push -u heroku master