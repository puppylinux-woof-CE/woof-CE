echo "For resolute with GCC-15: patch petbuilds.sh"
sed -i 's%ccache gcc\"%ccache gcc -fpermissive -std=gnu11\"%' support/petbuilds.sh
sed -i 's%ccache g++\"%ccache g++ -std=c++98\"%' support/petbuilds.sh
