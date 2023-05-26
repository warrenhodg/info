content=$(cat <file-to-upload> | base64 |tr --delete '\n')
curl -X "PUT" \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: token <token>" \
  https://api.github.com/repos/<org>/<repo>/contents/<file> \
  -d "{
  \"message\":\"<your commit message>\",
  \"committer\":{\"name\":\"<your name>\", \"email\":\"<your email>\"},
  \"content\":\"${content}\"
  }"
