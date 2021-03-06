describe '/ticket/comment/' do
    Scripts.createUser('commenter@os4.com', 'commenter', 'Commenter')
    Scripts.login('commenter@os4.com', 'commenter')

    result = Scripts.createTicket

    @ticketNumber = result['ticketNumber']

    it 'should fail if invalid token is passed' do
        result = request('/ticket/comment', {
            content: 'some comment content',
            ticketId: @ticketNumber,
            csrf_userid: $csrf_userid,
            csrf_token: 'INVALID_TOKEN'
        })

        (result['status']).should.equal('fail')
        (result['message']).should.equal('NO_PERMISSION')
    end

    it 'should fail if content is too short' do
        result = request('/ticket/comment', {
            content: 'Test',
            ticketNumber: @ticketNumber,
            csrf_userid: $csrf_userid,
            csrf_token: $csrf_token
        })

        (result['status']).should.equal('fail')
        (result['message']).should.equal('INVALID_CONTENT')
    end

    it 'should fail if content is very long' do
        long_text = ''
        6000.times {long_text << 'a'}

        result = request('/ticket/comment', {
            content: long_text,
            ticketNumber: @ticketNumber,
            csrf_userid: $csrf_userid,
            csrf_token: $csrf_token
        })

        (result['status']).should.equal('fail')
        (result['message']).should.equal('INVALID_CONTENT')
    end

    it 'should fail if ticket does not exist' do
        result = request('/ticket/comment', {
            content: 'some comment content',
            ticketNumber: 30,
            csrf_userid: $csrf_userid,
            csrf_token: $csrf_token
        })

        (result['status']).should.equal('fail')
        (result['message']).should.equal('INVALID_TICKET')
    end

    it 'should add comment to ticket' do
        result = request('/ticket/comment', {
            content: 'some comment content',
            ticketNumber: @ticketNumber,
            csrf_userid: $csrf_userid,
            csrf_token: $csrf_token
        })

        (result['status']).should.equal('success')

        ticket = $database.getRow('ticket', @ticketNumber, 'ticket_number')
        comment = $database.getRow('ticketevent', ticket['id'], 'ticket_id')
        (comment['content']).should.equal('some comment content')
        (comment['type']).should.equal('COMMENT')
        (comment['author_user_id']).should.equal($csrf_userid)
        (ticket['unread_staff']).should.equal('1')

        lastLog = $database.getLastRow('log')
        (lastLog['type']).should.equal('COMMENT')
    end

    it 'should fail if user is not the author nor owner' do
        Scripts.createUser('no_commenter@comment.com', 'no_commenter', 'No Commenter')
        Scripts.login('no_commenter@comment.com', 'no_commenter')

        result = request('/ticket/comment', {
            content: 'some comment content',
            ticketNumber: @ticketNumber,
            csrf_userid: $csrf_userid,
            csrf_token: $csrf_token
        })

        (result['status']).should.equal('fail')
        (result['message']).should.equal('NO_PERMISSION')

        request('/user/logout')
        Scripts.login($staff[:email], $staff[:password], true)
        request('/staff/add', {
            csrf_userid: $csrf_userid,
            csrf_token: $csrf_token,
            name: 'Jorah mormont',
            email: 'jorah@opensupports.com',
            password: 'testpassword',
            level: 2,
            profilePic: '',
            departments: '[1]'
        })

        request('/user/logout')
        Scripts.login('jorah@opensupports.com', 'testpassword', true)
        result = request('/ticket/comment', {
            content: 'some comment content',
            ticketNumber: @ticketNumber,
            csrf_userid: $csrf_userid,
            csrf_token: $csrf_token
        })

        (result['status']).should.equal('fail')
        (result['message']).should.equal('NO_PERMISSION')
    end
end
