paths=(
    'lambda/ssm_execute'
)
for p in $paths
do
    cd $p
    zip -r function.zip .
    cd ${OLDPWD}
done
