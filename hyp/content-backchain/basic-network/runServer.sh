 
cd ../server
#Install node modules
if [[ ! -d node_modules ]]; then
        echo "============== Installing node modules ============="
                npm install
fi
echo

PORT=4000 node app &> server.log

